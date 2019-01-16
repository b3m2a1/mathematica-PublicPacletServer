(* ::Package:: *)

(* Autogenerated Package *)

(* ::Subsubsection::Closed:: *)
(*Find*)



$AppDirectoryRoot::usage="The directory root for finding apps";
$AppDirectoryName::usage="The basic extension to a directory for locating apps";
$AppDirectory::usage="Joins the root and name";
$AppDirectories::usage="Set of directories in which to look for apps";
AppPath::usage=
  "A path parser for a given app name";


(* ::Subsubsection::Closed:: *)
(*Edit*)



AppConfigure::usage=
  "Compiles an application from a series of packages or definitions";
AppConfigureSubapp::usage=
  "Creates a subapplication out of a set of packages or specs";
AppReconfigureSubapp::usage=
  "Reconfigures a subapp, preserving files, etc.";


AppAddContent::usage="Adds a file to the app";


AppConfigRegenerate::usage="Regenerates a config file";


AppAddContextFiles::usage=
  "Adds files for loading specific contexts to an app";


(* ::Subsubsection::Closed:: *)
(*Analyze*)



AppGet::usage=
  "Runs get on the specified app package";
AppNeeds::usage=
  "Runs Needs on the specified package";
AppPackageOpen::usage=
  "Opens a package .m file";
AppFromFile::usage=
  "Gets an app from the current file";


(* ::Subsubsection::Closed:: *)
(*Distribute*)



$AppCloudExtension::usage="The cloud extension for applications";


AppPublish::usage=
  "Publishes the app to GitHub and PacletServer";


Begin["`Private`"];


(* ::Subsection:: *)
(*Load*)



If[Length@OwnValues[$AppDirectoryRoot]==0,
  $AppDirectoryRoot=$UserBaseDirectory;
  ];
If[Length@OwnValues[$AppDirectoryName]==0,
  $AppDirectoryName="Applications"
  ];
If[Length@OwnValues[$AppDirectory]==0,
  $AppDirectory:=
    FileNameJoin@{$AppDirectoryRoot, $AppDirectoryName}
  ];
If[Length@OwnValues[$AppDirectories]==0,
  $AppDirectories:=
    Prepend[
      Join[
        PacletManager`Package`$extraPacletDirs,
        $Path
        ],
      $AppDirectory
      ]
  ];
If[Length@OwnValues[$AppUploadDefault]==0,
  $AppUploadDefault="Cloud"
  ];
If[Length@OwnValues[$AppBackupDefault]==0,
  $AppBackupDefault=
    Which[
      DirectoryQ@FileNameJoin@{$HomeDirectory, "Google Drive"},
        "GoogleDrive",
      DirectoryQ@FileNameJoin@{$HomeDirectory, "Dropbox"},
        "Dropbox",
      DirectoryQ@FileNameJoin@{$HomeDirectory, "OneDrive"},
        "OneDrive",
      _,
        "Cloud"
      ]
  ];
If[$AppBuilderConfigLoaded=!=True,
  Replace[
    SelectFirst[
      PackageFilePath["Private", "Config", "AppBuilderConfig."<>#]&/@{"m","wl"},
      FileExistsQ
      ],
      f_String:>Get@f
    ];
  $AppBuilderConfigLoaded=True
  ];


(* ::Subsection:: *)
(*Builder*)



(* ::Subsubsection::Closed:: *)
(*AppPath*)



AppPath//Clear


Options[AppPath]=
  {
    "FormatPath"->True
    };
AppPath[
  format:True|False:False, 
  app:_String, 
  e___?(MatchQ[Flatten[{#}], {__String}]&)
  ]:=
  With[{base=AppDirectory[app, e]},
    If[!FileExistsQ@base,
      Replace[
        PacletManager`PacletFind[app],
        {
          {p_,___}:>
            FileNameJoin@Flatten@{p["Location"], AppPathFormat@{e}},
          _->base
          }
        ],
      base
      ]
    ];
(*AppPath[
	app:_String, 
	e___?(MatchQ[Flatten[{#}], {__String}]&),
	ops:OptionsPattern[]
	]:=*)


(* ::Subsubsection::Closed:: *)
(*AppConfigure*)



(* ::Subsubsubsection::Closed:: *)
(*configureDirectories*)



configureDirectories[name_String]:=
  Do[
    If[Not@DirectoryQ@
          FileNameJoin@Flatten@{$AppDirectory, dir},
      CreateDirectory@
        FileNameJoin@Flatten@{$AppDirectory, dir}
      ],
    {dir,
      Table[Flatten@{name,e},
        {e,
          {"Kernel",
            "FrontEnd",
            "Packages",
            {"Packages","__Future__"},
            {"FrontEnd","Palettes"},
            {"FrontEnd","Palettes",name},
            {"FrontEnd","StyleSheets"},
            {"FrontEnd","StyleSheets",name},
            "Documentation",
            {"Documentation","English"},
            "Config",
            "Private",
            "Resources",
            "Dependencies",
            $AppProjectExtension,
            {$AppProjectExtension, $AppProjectImages}
            }
          }]~Prepend~name
      }
    ];
AppRegenerateDirectories[app_String]:=
  configureDirectories[app];


(* ::Subsubsubsection::Closed:: *)
(*getDefinitions*)



getDefinitions[defs:(_Symbol|_String?(StringMatchQ[RegularExpression[".+`"]]))..]:=
  Replace[Thread[Hold[{defs}]],
    {Hold[def_String]:>
      Append[
        Prepend[
          ToExpression[Names@(def<>"*"),StandardForm,Hold],
          Hold["Begin[\""<>def<>"\"];"]
          ],
        "End[];"]
      },
    1]//Flatten//DeleteDuplicates//
  DeleteCases[#/.{
    Hold[s:Except[_Symbol]]:>s,
    Hold[s_]:>ToString[Definition[s],InputForm]
    },
    "Null"
    ]&//StringJoin@Riffle[#,"\n\n"]&;
getDefinitions~SetAttributes~HoldAll


(* ::Subsubsubsection::Closed:: *)
(*configurePackages*)



configurePackages[
  name_?StringQ,
  packages:(_String|_Symbol|{(_String|_Symbol|{_String,_String|{__String}})..})
  ]:=
  With[{
    files=
      Cases[
        Replace[Hold[packages],Hold[{p__}]:>Hold[p]],
        _String?FileExistsQ|{_String?FileExistsQ,_}
        ],
    defs=
      getDefinitions@@
        Replace[
          Thread[
            Cases[Replace[Hold[packages],Hold[{p__}]:>Hold[p]],
              s:(_Symbol|_String?(StringMatchQ[RegularExpression[".+`"]])):>Hold[s]
              ],
            Hold],
          Hold[{ds__}]:>Hold[ds]
          ]
    },
    If[MatchQ[defs,_String],
      With[{defFile=
        OpenWrite@
          FileNameJoin@{
            $AppDirectory,
            name,"Packages",
            "ContextPackage.m"
            }
          },
        WriteString[defFile,defs];
        Close@defFile;
        ]
      ];
    
    Do[
      If[DirectoryQ@
        If[StringQ@f,
          f,
          First@f
          ],
        CopyDirectory,
        CopyFile[##,OverwriteTarget->True]&
        ][
        If[StringQ@f,
          f,
          First@f
          ],
        (If[!FileExistsQ@#,
          If[DirectoryQ@
            If[StringQ@f,
              f,
              First@f
              ],
            Quiet[
              DeleteDirectory@#;
              CreateDirectory[DirectoryName@#,
                CreateIntermediateDirectories->True
                ]
              ],
            CreateFile@#
            ];
          ];#)&@
        AppPath[name,"Packages",
          If[StringQ@f,
            FileNameTake@f,
            Sequence@@Flatten@{Last@f}
            ]
          ]
        ],
      {f,files}
      ]
    ];
configurePackages~SetAttributes~HoldAll;


(* ::Subsubsubsection::Closed:: *)
(*configureDocs*)



configureDocs[
  app_String,
  docNotebooks:(_String|_File)?FileExistsQ..]:=
  Do[
    With[{f=
      FileNameJoin@Flatten@{
        $AppDirectory,
        app,
        "Documentation",
        "English",
        Replace[FileNameSplit@d,
          {___,"Documentation","English",p__}:>
            p
          ]
        }
      },
      CopyFile[d,f,
        OverwriteTarget->True]
      ],
    {d,docNotebooks}
    ]


(* ::Subsubsubsection::Closed:: *)
(*configureFE*)



configureFENewPath[
  app_,
  type_,
  old_
  ]:=
  With[{f=Replace[old,(b_->n_):>n]},
    Replace[FileNameSplit[f],{
      {___,type,r__}:>
        AppPath[app,type,r],
      {___,r_}:>
        AppPath[app,type,r]
      }]
    ]


configureFE[app_,
  stylesheets_,
  palettes_,
  textresources_,
  systemresources_
  ]:=
  MapThread[
    With[{type=#2,files=#},
      With[{f=Replace[#,(b_->n_):>b]},
        If[FileExistsQ[f],
          With[{path=configureFENewPath[app,type,#]},
            If[!DirectoryQ@DirectoryName[path],
              CreateDirectory[DirectoryName[path],
                CreateIntermediateDirectories->True
                ]
              ];
            If[DirectoryQ[f],
              CopyDirectory[f,path],
              CopyFile[f,path,
                OverwriteTarget->True
                ]
              ]
            ]
          ]
        ]&/@files
      ]&,{
    Replace[
      Flatten@*List/@{stylesheets,palettes,textresources,systemresources},
      Except[{(_String|_File|_Rule)...}]->{},
      1],
    {"StyleSheets","Palettes","TextResources","SystemResources"}
    }]


(* ::Subsubsubsection::Closed:: *)
(*configureResources*)



configureResourcesNewPath[
  app_,
  type_,
  old_
  ]:=
  With[{f=Replace[old,(b_->n_):>n]},
    Replace[FileNameSplit[f],{
      {___,type,r__}:>
        AppPath[app,type,r],
      {___,r_}:>
        AppPath[app,type,r]
      }]
    ]


configureResources[app_,
  resListing_
  ]:=
  MapThread[
    With[{type=#2,files=#},
      With[{f=Replace[#,(b_->n_):>b]},
        If[FileExistsQ[f],
          With[{path=configureResourcesNewPath[app,type,#]},
            If[!DirectoryQ@DirectoryName[path],
              CreateDirectory[DirectoryName[path],
                CreateIntermediateDirectories->True
                ]
              ];
            If[DirectoryQ[f],
              CopyDirectory[f,path],
              CopyFile[f,path,
                OverwriteTarget->True
                ]
              ]
            ]
          ]
        ]&/@files
      ]&,{
    Replace[
      Flatten@*List/@{resListing},
      Except[{(_String|_File|_Rule)...}]->{},
      1],
    {"Resources"}
    }]


(* ::Subsubsubsection::Closed:: *)
(*AppConfigure*)



Options[AppConfigure]=
  {
    Directory->Automatic,
    Extension->Automatic,
    "Documentation"->{},
    "StyleSheets"->{},
    "Palettes"->{},
    "TextResources"->{},
    "SystemResources"->{},
    "AutoCompletionData"->{},
    "Resources"->{},
    "PacletInfo"->{},
    "BundleInfo"->{},
    "LoadInfo"->{},
    "UploadInfo"->None
    };
AppConfigure[
  name_?StringQ,
  packages:
    (
      _Symbol|Except[_Symbol]?(MatchQ[(_String|_File)?FileExistsQ])
      )|
    {
      (
        _Symbol|Except[_Symbol]?(MatchQ[(_String|_File)?FileExistsQ])|
          {
            Except[_Symbol]?(MatchQ[(_String|_File)?FileExistsQ]),
            Except[_Symbol]?(MatchQ[_String|{__String}])
            }
        )...}|None:
    None,
  ops:OptionsPattern[]
  ]:=
  Block[{
    $AppDirectoryRoot=
      Replace[OptionValue@Directory,
        Automatic:>$AppDirectoryRoot],
    $AppDirectoryName=
      Replace[OptionValue@Extension,{
        Automatic:>$AppDirectoryName,
        Except[_String]->Nothing
        }]
    },
    configureDirectories@name;
    Replace[
      Hold[packages]/.{
        None->{},
        f:Except[_Symbol]:>
          With[{r=f},r/;True]
        },
      Hold[p__]:>configurePackages[name,p]
      ];
    AppRegenerateInit@name;
    configureDocs[name,
      Sequence@@Flatten@{OptionValue@"Documentation"}
      ];
    configureFE[name,
      OptionValue["StyleSheets"],
      OptionValue["Palettes"],
      OptionValue["TextResources"],
      OptionValue["SystemResources"]
      ];
    configureResources[name,
      OptionValue["Resources"]
      ];
    If[OptionValue["PacletInfo"]=!=None,
      AppRegeneratePacletInfo[name,
        Sequence@@Flatten@{OptionValue@"PacletInfo"}]
      ];
    If[OptionValue["LoadInfo"]=!=None,
      AppRegenerateLoadInfo[name, OptionValue["LoadInfo"]]
      ];
    If[OptionValue["UploadInfo"]=!=None,
      AppRegenerateUploadInfo[name, OptionValue["UploadInfo"]]
      ];
    If[OptionValue["BundleInfo"]=!=None,
      AppRegenerateBundleInfo[name, OptionValue["BundleInfo"]]
      ];
    FileNameJoin@{$AppDirectory, name}
    ];
AppConfigure~SetAttributes~HoldAll;


(* ::Subsubsection::Closed:: *)
(*AppConfigureSubapp*)



appConfigureSubResource[app_,new_,resType_,resList_]:=
  Map[
    #->
      StringReplace[#,
        StringTrim@FileNameJoin@{" ",app," "}->
          StringTrim@FileNameJoin@{" ",new," "}
        ]&
    ]@
  DeleteCases[Except[_String?(StringLength@#>0&&FileExistsQ@#&)]]@
  Map[
    SelectFirst[
      {
        AppPath[app,resType, #],
        AppPath[app,resType,
          StringTrim[#,".nb"]<>".nb"],
        AppPath[app,resType,app, #],
        AppPath[app,resType,app,
          StringTrim[#,".nb"]<>".nb"]
        },
      FileExistsQ,
      Nothing
      ]&,
    Flatten[{resList}, 1]
    ]


Options[AppConfigureSubapp]=
  DeleteDuplicatesBy[First]@
    Join[
      {
        "Name"->Automatic,
        "Packages"->{},
        "StyleSheets"->{},
        "Palettes"->{},
        "Documentation"->{},
        "Symbols"->{},
        "Guides"->{},
        "Tutorials"->{}
        },
      FilterRules[Options@AppConfigure,
        Except[Directory|Extension]
        ]
      ];
AppConfigureSubapp[
  appName_:Automatic,
  path_String?(StringLength@DirectoryName@#>0&&FileExistsQ@DirectoryName@#&),
  ops:OptionsPattern[]
  ]:=
  With[{app=AppFromFile[appName]},
    With[{
      packages=
        Map[
          {#,
            FileNameSplit@
              FileNameDrop[#,FileNameDepth@AppDirectory[app,"Packages"]]
            }&
          ]@
            DeleteCases[Except[_String?(StringLength@#>0&&FileExistsQ@#&)]]@
            Flatten[
              {
                AppPackage[app,StringTrim[#,".nb"|".m"|".wl"]],
                Replace[
                  AppPackage[app,
                    StringTrim[#,".nb"|".m"]<>".m"
                    ],
                  $Failed:>
                    AppPackage[app,
                      StringTrim[#,".nb"|".wl"]<>".wl"
                      ]
                  ]
                }&/@
                Replace[Flatten[{OptionValue["Packages"]},1],
                  Except[_String]->Nothing,
                  1
                  ]
              ],
      palettes=
        appConfigureSubResource[app,FileBaseName[path],
          "Palettes",
          OptionValue["Palettes"]
          ],
      stylesheets=
        appConfigureSubResource[app,FileBaseName[path],
          "StyleSheets",
          OptionValue["StyleSheets"]
          ],
      textresources=
        appConfigureSubResource[app,FileBaseName[path],
          "TextResources",
          OptionValue["TextResources"]
          ],
      systemresources=
        appConfigureSubResource[app,FileBaseName[path],
          "SystemResources",
          OptionValue["SystemResources"]
          ],
      resources=
        appConfigureSubResource[app,FileBaseName[path],
          "Resources",
          OptionValue["Resources"]
          ],
      docs=
        {}(*DeleteCases[Except[_String?(StringLength@#>0&&FileExistsQ@#&)]]@
				Join[
					AppPath[app,"Symbols",
						StringTrim[#,".nb"]<>".nb"]&/@
							Flatten@{OptionValue["Symbols"]},
					AppPath[app,"Symbols",
						StringTrim[#,".nb"]<>".nb"]&/@
							Flatten@{OptionValue["Guides"]},
					AppPath[app,"Symbols",
						StringTrim[#,".nb"]<>".nb"]&/@
							Flatten@{OptionValue["Tutorials"]},
					AppPath[app,"Documentation","English",
						If[StringQ@#,StringTrim[#,".nb"]<>".nb",#]
						]&/@
							Flatten@{OptionValue["Documentation"]}
					]*)
      },
      AppConfigure[
        FileBaseName@path,
        packages,
        Evaluate@FilterRules[{
          "Palettes"->palettes,
          "StyleSheets"->stylesheets,
          "TextResources"->textresources,
          "SystemResources"->systemresources,
          "Documentation"->docs,
          "Resources"->resources,
          Directory->DirectoryName@path,
          Extension->None,
          ops
          },
          Options@AppConfigure
          ]
        ]
      ]
    ];
AppConfigureSubapp[
  app_,
  name:_String|{__String},
  dir:(_String?DirectoryQ|Automatic):Automatic,
  ops:OptionsPattern[]
  ]:=
  With[{
    appName=
      Replace[OptionValue@"Name",
        Automatic:>
          First@Flatten@{name}
        ],
    buildd=Replace[dir,Automatic:>$TemporaryDirectory]
    },
    AppConfigureSubapp[
      app,
      Quiet@
        DeleteDirectory[
          FileNameJoin@{buildd,appName},
          DeleteContents->True
          ];
      FileNameJoin@{buildd,appName},
      FilterRules[{
        "Packages"->
          Join[
            #,
            OptionValue["Packages"]
            ],
        ops,
        "LoadInfo"->{
          "PackageScope"->
            DeleteCases[
              Select[#,StringQ],
              Alternatives@@Flatten@{name}
              ]
          }
        },
        Options@AppConfigureSubapp
        ]&@Keys@AppPackageDependencies[app,name]
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*AppReconfigureSubapp*)



appCopyContent[
  files_,
  oldDir_,
  newDir_
  ]:=
  With[
      {
        old=
          FileNameJoin@
            Flatten@
              {
                oldDir,
                AppPathFormat[#]
                },
        new=
          FileNameJoin@
            Flatten@{
              newDir,
              AppPathFormat[#]
              }
        },
      If[FileExistsQ@old,
        If[!DirectoryQ@DirectoryName[new],
          CreateDirectory[DirectoryName[new],
            CreateIntermediateDirectories->True]
          ];
        If[DirectoryQ@old,
          If[DirectoryQ@new,
            DeleteDirectory[new,DeleteContents->True]
            ];
          CopyDirectory[old,new],
          CopyFile[old,new,
            OverwriteTarget->True
            ]
          ]
        ]
      ]&/@files


Options[AppReconfigureSubapp]=
  Join[
    Options[AppConfigureSubapp],
    {
      "PreserveFiles"->
        {
          ".git", 
          ".gitignore",
          "README.md",
          "README.nb",
          "project"
          },
      "PreservePacletInfo"->True
      }
    ];
AppReconfigureSubapp[
  app_,
  name:_String|{__String},
  dir:(_String?DirectoryQ|Automatic):Automatic,
  ops:OptionsPattern[]
  ]:=
  Module[
    {
      appName=
        Replace[OptionValue@"Name",
          Automatic:>
            First@Flatten@{name}
          ],
      appDir,
      presFiles=
        OptionValue["PreserveFiles"],
      presPI=
        OptionValue["PreservePacletInfo"],
      tmp
      },
    appDir=
      FileNameJoin@{
        Replace[dir,
          Automatic:>
            $TemporaryDirectory
          ],
        appName
        };
    tmp=CreateDirectory[];
    CheckAbort[
      appCopyContent[presFiles,appDir,tmp];
      AppConfigureSubapp[
        app,
        name,
        dir,
        If[presPI,
          "PacletInfo"->
            Flatten@
              {
                Replace[OptionValue["PacletInfo"],
                  Except[_List]->{}
                  ],
                  Normal@PacletInfoAssociation[appDir]
                  },
          Sequence@@{}
          ],
        ops
        ];
      appCopyContent[presFiles,tmp,appDir];
      DeleteDirectory[tmp,
        DeleteContents->True],
      DeleteDirectory[tmp,
        DeleteContents->True]
      ];
    appDir
    ]


(* ::Subsubsection::Closed:: *)
(*Regens*)



$AppRegenRouter:=
  <|
      "PacletInfo"->
        AppRegeneratePacletInfo,
      "Loader"->
        AppRegenerateInit,
      "Directories"->
        AppRegenerateDirectories,
      "ContextLoaders"->
        AppRegenerateContextLoadFiles,
      "LoadInfo"->
        AppRegenerateLoadInfo,
      "BundleInfo"->
        AppRegenerateBundleInfo,
      "UploadInfo"->
        AppRegenerateUploadInfo,
      "DocInfo"->
        AppRegenerateDocInfo,
      "README"->
        AppRegenerateReadme,
      "GitIgnore"->
        AppRegenerateGitIgnore,
      "GitExclude"->
        AppRegenerateGitExclude
    |>;
AppConfigRegenerate[app_, thing_?(KeyExistsQ[$AppRegenRouter, #]&), args___]:=
  $AppRegenRouter[thing][app, args];


(* ::Subsection:: *)
(*Edit*)



(* ::Subsubsection::Closed:: *)
(*Add Content*)



Options[AppAddContent]=
  Join[(*
		Options[CreateDirectory],*)
    Options[CopyFile]
    ];
AppAddContent//Clear
AppAddContent[
  name_,
  file_String?FileExistsQ,
  path__String,
  ops:OptionsPattern[]
  ]:=
  With[
    {
      copyTo=
        AppPath[name,path,FileNameTake@file]
      },
    If[Not@FileExistsQ@DirectoryName@copyTo,
      CreateDirectory[DirectoryName@copyTo,
        CreateIntermediateDirectories->True
        ]
      ];
    CopyFile[file,copyTo,
      FilterRules[{ops}, Options@CopyFile]
      ]
    ];
AppAddContent[
  name_,
  file_String?(FileExistsQ),
  ops:OptionsPattern[]
  ]:=
  With[{path=
    Switch[
      {FileBaseName@file, FileExtension@file},
      {"PacletInfo","m"},{},
      {_?(StringEndsQ["Info"]), "m"}, "Config",
      {_,"m"|"wl"},"Packages",
      {_, "nb"},
        Replace[
          Get@file,
          {
            nb:Notebook[data_,
              {___,
                StyleDefinitions->_?(
                    Not@*FreeQ@FrontEnd`FileName[{"Wolfram"},"Reference"]
                    ),___}]:>
                If[FreeQ[data,Cell[__,"GuideTitle",___]],
                  "Symbols",
                  "Guides"
                  ],
            Notebook[_,
              {___,(_Rule|_RuleDelayed)[AutoGeneratedPackage,Except[False]],___}]->
              "Packages",
            Notebook[
              _?(MemberQ[#, Cell[StyleData[__],___], Infinity]&),
              ___
            ]->
              {"StyleSheets", name},
            _->"Resources"
            }
          ],
      _,{}
      ]},
    AppAddContent[name, file, Sequence@@Flatten[{path}], ops]
    ];
AppAddContent[
  appName_,
  nb:(_NotebookObject|Automatic):Automatic,
  ops:OptionsPattern[]
  ]:=
  Replace[
    NotebookFileName@Replace[nb,Automatic:>EvaluationNotebook[]],
    {
      fName_String:>AppAddContent[appName, nb, FileBaseName@fName, ops],
      _:>$Failed
      }
    ];
AppAddContent[
  appName_,
  nb:(_NotebookObject|Automatic):Automatic,
  fName_String?(StringMatchQ[Except[$PathnameSeparator]..]),
  path:__String|None:None,
  ops:OptionsPattern[]
  ]:=
  With[{file=
      NotebookSaveRename[
        Replace[nb, Automatic:>EvaluationNotebook[]],
        FileNameJoin@{
          $TemporaryDirectory,
          fName<>If[FileExtension[fName]==="", ".nb", ""]
          }
        ]},
    With[{new=
      Check[
        If[{path}=!={None},
          AppAddContent[appName, file, Sequence@@Flatten[{path}], ops],
          AppAddContent[appName, file, ops]
          ],
        $Failed]},
      If[MatchQ[new, _String?FileExistsQ],
        SystemOpen@new;
        NotebookClose@Replace[nb, Automatic:>EvaluationNotebook[]],
        $Failed
        ]
      ]
    ];


(* ::Subsection:: *)
(*Publish*)



(* ::Subsubsection::Closed:: *)
(*AppPublish*)



Options[AppPublish]=
  {
    "PacletBackup"->True,
    "UpdatePaclet"->True,
    "GitCommit"->Automatic,
    "ConfigureGitHub"->Automatic,
    "PushToGitHub"->True,
    "PushToCloud"->False,
    "PushToServer"->True,
    "PublishServer"->Automatic,
    "MakeSite"->True,
    Verbose->True
    };
AppPublish[app_,ops:OptionsPattern[]]:=
  With[{
    updatePac=TrueQ[OptionValue["UpdatePaclet"]],
    gitCommit=OptionValue["GitCommit"],
    gitHubConfigure=OptionValue["ConfigureGitHub"],
    gitHubPush=TrueQ[OptionValue["PushToGitHub"]],
    pacletCloudPush=TrueQ[OptionValue["PushToCloud"]],
    pacletServerPush=TrueQ[OptionValue["PushToServer"]],
    pacletBackup=TrueQ[OptionValue["PacletBackup"]],
    verb=TrueQ@OptionValue[Verbose]
    },
    <|
      "PacletBackup"->
        If[pacletBackup,
          AppPacletBackup[app]
          ],
      "UpdatePaclet"->
        If[updatePac,
          AppRegeneratePacletInfo[app]
          ],
      "GitCommit"->
        If[TrueQ[gitCommit]||(gitHubPush&&gitCommit=!=False),
          AppGitSafeCommit[app]
          ],
      "ConfigureGitHub"->
        If[TrueQ[gitHubConfigure]||(gitHubPush&&gitHubConfigure=!=Automatic),
          AppGitHubConfigure[app]
          ],
      "PushToGitHub"->
        If[gitHubPush,
          Quiet[AppGitHubPush[app], Git::err];
          AppGitHubRepo[app]
          ],
      "PushToCloud"->
        If[pacletCloudPush,
          AppPacletUpload[app]
          ],
      "PushToServer"->
        Association@{
          If[TrueQ@pacletServerPush,
            "ServerPaclet"->
              PacletServerAdd[$PacletServer, 
                AppPacletBundle[app]
                ],
            Nothing
            ],
          If[TrueQ@OptionValue["PublishServer"]||
            TrueQ[pacletServerPush]&&OptionValue["PublishServer"]===Automatic,
            "ServerURL"->
              With[{mf=TrueQ@OptionValue["MakeSite"]},
                Replace[
                  MinimalBy[
                    Select[
                      Cases[
                        PacletServerBuild[$PacletServer, 
                          "AutoDeploy"->True,
                          "RegenerateContent"->mf,
                          "BuildSite"->mf,
                          "DeployOptions"->
                            {
                              Monitor->False,
                              "DeployPages"->mf
                              }
                          ],
                        CloudObject[c_,___]:>c
                        ],
                      StringEndsQ["/index.html"]
                      ],
                    Length@URLParse[#,"Path"]&
                    ],
                  {m_, ___}:>
                    m
                  ]
                ],
              Nothing
              ]
            }
      |>
    ]


(* ::Subsection:: *)
(*Loading*)



(* ::Subsubsection::Closed:: *)
(*AppGet*)



AppGet::nopkg="Couldn't find package `` in app ``";


AppGet[appName_, pkgName_String]:=
  With[{
    app=AppFromFile[appName],
    cont=$Context
    },
    Replace[
      SortBy[Length@StringSplit[#, "`"]&]@
        Names[app<>"`*`PackageAppGet"],{
        {n_, ___}:>
          Replace[
            FileNames[
              pkgName~~".wl"|".m",
              AppPath[app, "Packages"],
              \[Infinity]
              ],
            {
              {f_,___}:>
                ToExpression[n][pkgName],
              _:>(Message[AppGet::nopkg, pkgName, app];$Failed)
              }
            ],
      _:>(
        If[DirectoryQ@AppPath[app,"Packages",pkgName],
          BeginPackage[app<>"`"];
          Begin["`"<>StringTrim[StringReplace[pkgName,$PathnameSeparator->"`"],"`"]<>"`"];
          FrontEnd`Private`GetUpdatedSymbolContexts[];
          EndPackage[],
          With[{
            pkg=
              SelectFirst[
                SortBy[FileNameDepth]@
                  FileNames[
                    StringTrim[pkgName, ".m"|".wl"]~~(".m"|".wl"),
                    AppPath[app,"Packages"],
                    Infinity
                    ],
                FileExistsQ
                ]
            },
            If[FileExistsQ@pkg,
              With[{
                pkCont=
                  StringReplace[
                    app<>"`"<>
                      StringReplace[
                        FileNameDrop[DirectoryName@pkg,
                          FileNameDepth@AppDirectory[app,"Packages"]],
                        $PathnameSeparator->"`"
                        ]<>"`",
                    "``"->"`"
                    ]
                },
                BeginPackage[pkCont]
                ];
              $ContextPath=
                DeleteDuplicates@
                  Join[
                    Replace[
                      ToExpression[
                        $Context<>"PackageScope`Private`$PackageContexts"
                        ],
                      Except[{__String}]->{}
                      ],
                    $ContextPath
                    ];
              CheckAbort[
                Get@pkg;
                EndPackage[],
                EndPackage[];
                Catch[
                  Catch[
                    Do[
                      If[i<100,
                        If[$Context===cont,Throw[$Context,"success"],End[]],
                        Throw[$Failed,"fail"]
                        ],
                      {i,1000}
                      ],
                    "fail",
                    Begin[cont]&
                    ],
                  "success"
                  ];
                ]
              ]
            ]
          ];
        Catch[
          Catch[
            Do[
              If[i<100,
                If[$Context===cont, Throw[$Context,"success"],End[]],
                Throw[$Failed,"fail"]
                ],
              {i,1000}
              ],
            "fail",
            Begin[cont]&
            ],
          "success"
          ]
        )
    }]
  ];
AppGet[appName_, pkgName:{__String}]:=
  AppGet[appName, FileNameJoin@pkgName];
AppGet[appName_,Optional[Automatic,Automatic]]:=
  Module[
    {
      app=AppFromFile[appName],
      baseDir,
      baseName,
      appPath
      },
    baseDir=AppDirectory[app];
    baseName=
      If[MatchQ[appName, NotebookObject],
        NotebookFileName[appName],
        NotebookFileName[]
        ];
    appPath=
      StringTrim[
        StringTrim[
          StringTrim[baseName, 
            FileNameJoin@{baseDir, "Packages"}],
          "."<>FileExtension[baseName]
          ],
        "/"
        ];
    AppGet[app, appPath]
    ];
AppGet[Optional[Automatic,Automatic]]:=
  Module[
    {
      baseName=
        FileNameTake[NotebookFileName[], {FileNameDepth@$AppDirectory+1}]
      },
    AppGet[baseName,Automatic]
    ];


(* ::Subsubsection::Closed:: *)
(*AppNeeds*)



If[Not@AssociationQ@$AppLoadedPackages,
  $AppLoadedPackages=<||>
  ];
AppNeeds[appName_,pkgName_String]:=
  If[!Lookup[$AppLoadedPackages,Key@{appName,pkgName},False],
    $AppLoadedPackages[{appName,pkgName}]=True;
    AppGet[appName,pkgName];
    ];
AppNeeds[appName_,Optional[Automatic,Automatic]]:=
  AppNeeds[appName,FileBaseName@NotebookFileName[]];
AppNeeds[Optional[Automatic,Automatic]]:=
  With[{app=FileNameTake[NotebookFileName[],{FileNameDepth@$AppDirectory+1}]},
    AppNeeds[app,Automatic]
    ];


(* ::Subsubsection::Closed:: *)
(*AppFromFile*)



AppFromFile[f_String]:=
  If[FileExistsQ@AppDirectory[f],
    FileBaseName@f,
    With[
      {
        splitPath=FileNameSplit[DirectoryName[ExpandFileName@f]]
        },
      Replace[
        SelectFirst[
          Range[Length@splitPath, 1, -1],
          AnyTrue[
            {"PacletInfo.m", "Packages", "Resources"},
            With[{bp=Take[splitPath, #]},
              FileExistsQ@FileNameJoin@Append[bp, #]&
              ]
            ]&,
          Which[
            StringMatchQ[ExpandFileName@f,$AppDirectory~~__],
              FileNameTake[
                FileNameDrop[f,FileNameDepth@$AppDirectory],
                1
                ],
            StringMatchQ[f,"http*"~~"/"~~WordCharacter..],
              URLParse[f]["Path"]//Last,
            MemberQ[FileNameTake/@AppNames["*", False], f],
              f,
            Length@PacletManager`PacletFind[f]>0,  
              PacletManager`PacletFind[f][[1]]["Location"]//FileBaseName,
            True,
              $Failed
            ]
          ],
        i_Integer:>
          splitPath[[i]]
        ]
      ]
  ];
AppFromFile[nb_NotebookObject]:=
  Replace[Quiet@NotebookFileName[nb],
    s_String:>
      AppFromFile[s]
    ];
AppFromFile[Optional[Automatic,Automatic]]:=
  AppFromFile@InputNotebook[];


(* ::Subsubsection::Closed:: *)
(*AppPackageOpen*)



AppPackageOpen[app_:Automatic,pkg_]:=
  Replace[AppPackage[app,pkg<>".m"],{
    f_String?FileExistsQ:>
      SystemOpen@f,
    _->$Failed
    }];
AppPackageOpen[Optional[Automatic,Automatic]]:=
  Replace[Quiet@NotebookFileName[],
    f_String:>
      AppPackageOpen[Automatic,
        FileBaseName@f
        ]
    ]


End[];



