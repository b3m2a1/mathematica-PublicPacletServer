(* ::Package:: *)

(* Autogenerated Package *)

$ReviewQueueDir::usage="";
$BuildDir::usage="";


UpdateQueue::usage=
  "Downloads paclets to be commited to the review queue";
BuildLog::usage=
  "Builds the paclet log";
AddPaclets::usage=
  "Adds the paclets in the review queue";
BuildPages::usage=
  "Builds the pages";
TestServer::usage=
  "Opens a test server";
PushServer::usage=
  "Pushes the server to GitHub";


Begin["`Private`"];


PublicPacletServer; (* invoke the autoloader *)


(* ::Subsubsection::Closed:: *)
(*Constants*)



$BuildDir:=
  $BuildDir=
    If[StringQ@$Clone&&DirectoryQ@$Clone,
      FileNameJoin@{$Clone, "build"},
      None
      ];


$ReviewQueueDir:=
  $ReviewQueueDir=
    If[StringQ@$Clone&&DirectoryQ@$Clone,
      FileNameJoin@{$Clone, "ReviewQueue"},
      None
      ];


(* ::Subsubsection::Closed:: *)
(*UpdateQueue*)



(* ::Subsubsubsection::Closed:: *)
(*buildIncludedPacletsFile*)



getSinglePacString[data_, str_]:=
  StringTrim[
    "(* ::Subsubsection::Closed:: *)\n(*"<>data["Name"]<>"*)\n\n"<>
      "$IncludedPaclets["<>ToString[data["Name"], InputForm]<>"]="<>
      str
    ]


buildIncludedPacletsFile[file_, pacs_]:=
  Module[
    {
      template=
        Import[
          PackageFilePath["Resources", "Templates", "IncludedPaclets.wl"],
          "Text"
          ],
      key="<*Insert Paclets*>",
      pacStrings,
      fill
      },
    pacStrings=
      StringJoin/@Partition[
        StringSplit[
          StringTrim[PrettyString[pacs], "{"|"}"], 
          "|>,"->"|>"
          ],
        UpTo[2]
        ];
    fill=
      StringRiffle[
        MapThread[
          getSinglePacString,
          {
            pacs,
            pacStrings
            }
          ],
        "\n\n"
        ];
    Export[
      file,
      StringReplace[template,
        key->fill,
        1
        ],
      "Text"
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*getCurrentPacletVersion*)



getCurrentPacletVersion//Clear
getCurrentPacletVersion[lists_]:=
  If[Length@lists==0,
    "0.0.0",
    Last@SortBy[
      Lookup[
        lists,
        "Version", 
        "0.0.0"
        ],
      getSemVerList
      ]
    ];
getCurrentPacletVersion[name_String, pacDir_]:=
  getCurrentPacletVersion@
    Map[
      PacletManager`PacletInformation,
      FileNames[name<>"*.paclet", 
        FileNameJoin@{pacDir, "Paclets"}
        ]
      ]


(* ::Subsubsubsection::Closed:: *)
(*getSemVerList*)



getSemVerList[version_]:=
  ToExpression@StringSplit[version, "."]


(* ::Subsubsubsection::Closed:: *)
(*getPacletNewerQ*)



getPacletNewerQ[currVersion_, newVersion_]:=
  newVersion!=currVersion&&
    newVersion==
      Last@
        SortBy[
          {newVersion, currVersion}, 
          getSemVerList
          ];


(* ::Subsubsubsection::Closed:: *)
(*loadPacletBlah*)



loadPacletBlah[extras_, logMerge_, log_, dir_, pacDir_]:=
  Module[
    {
      pacletLastTime,
      pacletUpdateRate,
      pacletUpdateFlag,
      paclet,
      addedSites,
      currSites,
      currVersion,
      newVersion,
      newerQ
      },
    Internal`WithLocalSettings[
        currSites=
          AssociationMap[False&, First/@PacletManager`PacletSites[]],
        Table[
          pacletUpdateRate=Lookup[e, "Update", Automatic(*"DownloadOnce"*)];
          Which[
            pacletUpdateRate===Automatic,
              pacletUpdateFlag=Automatic,
            pacletUpdateRate==="DownloadNever",
              pacletUpdateFlag=False,
            pacletUpdateRate==="DownloadOnce",
              e["Update"]="DownloadNever";
              pacletUpdateFlag=True,
            pacletUpdateRate==="DownloadAlways",
              pacletUpdateFlag=True,
            QuantityQ@pacletUpdateRate,
              pacletUpdateFlag=
                TrueQ[(Now-logMerge["Date"])>pacletUpdateRate]
            ];
          Switch[pacletUpdateFlag,
            True,
              Which[
                KeyExistsQ[e, "Site"], 
                  If[!KeyExistsQ[currSites, e["Site"]],
                    PacletManager`PacletSiteAdd[e["Site"]];
                    PacletManager`PacletSiteUpdate[e["Site"]]
                    ];
                  paclet=
                    PacletExecute["Download", e["Name"]],
                KeyExistsQ[e, "URL"],
                  paclet=PacletExecute["Download", e["URL"]],
                True,
                  paclet=$Failed
                ];,
            Automatic,
              Which[
                KeyExistsQ[e, "Site"], 
                  If[!KeyExistsQ[currSites, e["Site"]],
                    PacletManager`PacletSiteAdd[e["Site"]];
                    PacletManager`PacletSiteUpdate[e["Site"]]
                    ];
                  currVersion=
                    getCurrentPacletVersion[e["Name"], pacDir];
                  newVersion=
                    getCurrentPacletVersion@
                      Select[
                        PacletManager`PacletInformation/@
                          PacletManager`PacletFindRemote[e["Name"]],
                        Lookup[#, "Location"]==e["Site"]&
                        ];
                  If[TrueQ@getPacletNewerQ[currVersion, newVersion],
                    paclet=
                      PacletExecute["Download", e["Name"]],
                    paclet=None
                    ],
                KeyExistsQ[e, "URL"]&&
                  GitHub["ReleaseQ", e["URL"]],
                  currVersion=
                    getCurrentPacletVersion[e["Name"], pacDir];
                  newVersion=
                    PPSGitHubCheck@
                      GitHub["Releases", e["URL"], "ResultObject"];
                  newVersion=
                    SelectFirst[
                      First/@Lookup[
                        newVersion["Assets"],
                        "BrowserDownloadURL",
                        URL[""]
                        ],
                      StringEndsQ[".paclet"],
                      "https://www.fake.com/asd-0.0.0.paclet"
                      ];
                  newVersion=
                    StringTrim[
                      StringSplit[URLParse[newVersion, "Path"][[-1]], "-"][[2]],
                      ".paclet"
                      ];
                  If[TrueQ@getPacletNewerQ[currVersion, newVersion],
                    paclet=PacletExecute["Download", e["URL"]],
                    None
                    ],
                True,
                  paclet=None
                ],
            _,
              paclet=None
            ];
          If[StringQ@paclet&&FileExistsQ@paclet,
            paclet=
              Quiet@RenameFile[paclet, 
                FileNameJoin@{dir, "ReviewQueue", FileNameTake@paclet}]
            ];
          If[StringQ@paclet&&FileExistsQ@paclet,
            AppendTo[log, 
              e["Name"]->
                <|
                  "Date"->Now,
                  "Message"->
                    TemplateApply[
                      "Downloaded paclet `` from ``",
                      {
                        e["Name"],
                        Lookup[e, "Site", e["URL"]]
                        }
                      ],
                  "Author"->e["Author"]
                  |>
              ]
            ];
          e,
          {e, extras}
          ],
      KeyValueMap[
        If[#2, PacletManager`PacletSiteRemove[#]]&, 
        currSites
        ]
      ]
    ];
loadPacletBlah~SetAttributes~HoldRest


(* ::Subsubsubsection::Closed:: *)
(*UpdateQueue*)



(* ::Text:: *)
(*
	This needs to be chunked. It\[CloseCurlyQuote]s almost unmaintainable as is.
*)



UpdateQueue[ops:OptionsPattern[]]:=
  Module[
    {
      dir=$Clone,
      pacDir=$Paclets,
      log,
      logMerge,
      extras,
      extrasString
      },
    extras=
      Get@FileNameJoin@{dir, "ReviewQueue", "IncludedPaclets.wl"};
    log=
      Select[
        Get@FileNameJoin@{dir, "logs", "download_log.wl"},
        OptionQ
        ];
    logMerge=
      Merge[log, Last];
    logMerge=
      Map[
        If[StringQ@#Date,
          ReplacePart[#, "Date":>DateObject[#Date]],
          #
          ]&,
        logMerge
        ];
    extras=
      loadPacletBlah[extras, logMerge, log, dir, pacDir];
    buildIncludedPacletsFile[
      FileNameJoin@{dir, "ReviewQueue", "IncludedPaclets.wl"},
      extras
      ];
    log=
      If[Length@log>0,
        MapAt[
          ReplacePart[#, "Date"->DateString[#Date]]&,
          log,
          {All, 2}
          ],
        log
        ];
    PrettyExport[
      FileNameJoin@{dir, "logs", "download_log.wl"},
      log
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*BuildLog*)



(* ::Text:: *)
(*
	Not quite there yet. 
	Should find way to attach association log for use in index.
*)



(* ::Subsubsubsection::Closed:: *)
(*buildLogMD*)



buildLogMDKV[key_, val_DateObject?DateObjectQ]:=
  "* "<>ToString[key]<>": "<>DateString[val, "DateTime"];
buildLogMDKV[key_, val_]:=
  "* "<>ToString[key]<>": "<>ToString[val];
buildLogMDChunks[a:{__Association}]:=
  StringRiffle[
    "*** "<>DateString[#Date, "Date"]<>" ***\n"<>
      StringRiffle[
        KeyValueMap[buildLogMDKV, KeyDrop[#, {"Commit", "Date", "Message"}]], 
        "\n"
        ]<>"\n"<>StringReplace[#Message, StartOfString|StartOfLine->"\n>"]&/@a, 
    "\n\n"
    ];
buildLogMDBit[name_String, a:{__Association}]:=
  "<a id=\"`Name`\" style=\"width:0;height:0;margin:0;padding:0;\">&zwnj;</a>
## `Name`

`Log`

"~TemplateApply~
  <|
    "Log"->buildLogMDChunks[a], 
    "Name"->name
    |>;
buildLogMD[a_Association]:=
  "# Paclet Server Log

``
"~TemplateApply~StringRiffle[KeyValueMap[buildLogMDBit, a], "\n---\n"];


(* ::Subsubsubsection::Closed:: *)
(*BuildLog*)



BuildLog[ops:OptionsPattern[]]:=
  Module[
    {
      dir=$Clone,
      fds,
      gitPieces,
      downloadPieces,
      manualPieces,
      logStuff
      },
    Git["Add", dir, "All"->True];
    Git["Commit", 
      dir,
      "Message"->TemplateApply["Prelog commit", DateString[]],
      "All"->True
      ];
    fds=
      Normal@
        Git["FileHistory", 
          dir, 
          "*/*.paclet"
          ];
    gitPieces=
      Values@*Merge[First@*First]/@
        GroupBy[
          Normal@fds,
          StringSplit[#[[1]] ,"/"|"-"][[2]]&->Last
          ];
    gitPieces=
      KeySelect[gitPieces,
        Length@
          FileNames[
            #<>"*",
            FileNameJoin@{dir, "Paclets"}
            ]>0&
        ];
    downloadPieces=
      Get[FileNameJoin@{dir, "logs", "download_log.wl"}];
    manualPieces=
      Get[FileNameJoin@{dir, "logs", "manual_log.wl"}];
    logStuff=
      Merge[
        {
          gitPieces,
          downloadPieces,
          manualPieces
          }//.
          k:KeyValuePattern[{"Date"->d_String}]:>
            RuleCondition[ReplacePart[k, "Date"->DateObject[d]], True],
        Select[
          Reverse@
            SortBy[
              Flatten@#, 
              Key["Date"]
              ],
          Not[
            StringTrim[#["Author"]]=="b3m2a1 <b3m2a1@gmail.com>"&&
            StringQ@#["Commit"]&&
            (StringMatchQ[#Message, "Prelog commit"]||
              StringContainsQ[#Message, "Rebuilt on "])
            ]&
          ]&
        ];
    logStuff=
      Reverse@
        SortBy[
          logStuff,
          Max@Lookup[#, "Date"]&
          ];
    Export[
      FileNameJoin@{dir, "content", "pages", "log.md"},
      buildLogMD[logStuff],
      "Text"
      ];
    PrettyExport[
      FileNameJoin@{dir, "logs", "log.wl"},
      logStuff//.
        k:KeyValuePattern[{"Date"->d_DateObject}]:>
          RuleCondition[ReplacePart[k, "Date"->DateString[d]], True]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*BuildPacletSite*)



(* ::Subsubsubsection::Closed:: *)
(*buildPacletLocation*)



buildPacletLocation[p_]:=
  URLBuild@
    <|
      "Scheme"->"http",
      "Domain"->"raw.githubusercontent.com",
      "Path"->{
        "paclets", "Repository", "master" (*, "Paclets"*)(*,
				p["Name"]<>"-"<>p["Version"]<>".paclet" *)
        }
      |>;


(* ::Subsubsubsection::Closed:: *)
(*cleanPacletLocation*)



cleanPacletLocation[l_]:=
  If[GitHub["ReleaseQ", l],
    Module[{rel},
      rel=
        PPSGitHubCheck@
          GitHub["Releases", l, "ResultObject"];
      SelectFirst[
        First/@
          Lookup[rel["Assets"], "BrowserDownloadURL", URL[""]],
        StringEndsQ[".paclet"],
        l
        ]
      ],
    l
    ]


(* ::Subsubsubsection::Closed:: *)
(*BuildPacletSite*)



BuildPacletSite[ops:OptionsPattern[]]:=
  Module[
    {
      dir=$Clone,
      pacs=$Paclets,
      coreSite,
      coreData,
      pacletDataRaw,
      extraParameters,
      pacletData,
      pacletSite,
      siteMZ,
      oldSite
      },
    coreSite=PacletExecute["PacletSite", pacs];
    coreData=PacletExecute["SiteDataset", pacs];
    extraParameters=
      FileNameJoin@{dir, "ReviewQueue", "ExtraPacletInfo.wl"};
    extraParameters=
      Replace[Except[_?OptionQ]-><||>]@
        If[FileExistsQ@extraParameters, Import[extraParameters]];
    pacletData=
      Normal@
        coreData[
          SortBy[
            {
              #["Name"]&, 
              -1*ToExpression[StringSplit[#["Version"], "."]]&
              }
            ]
          ][
          DeleteDuplicatesBy["Name"]
          ];
    pacletData=
      Map[
        Join[
          #,
          Lookup[extraParameters, #["Name"], <||>]
          ]&,
        pacletData
        ];
    pacletData=
      Map[
        Append[#,
          "Location"->
            cleanPacletLocation@
              Lookup[#, "Location", buildPacletLocation[#]]
          ]&,
        pacletData
        ];
    pacletSite=
      PacletExecute["SiteFromDataset", pacletData];
    oldSite=
      PacletExecute["PacletSite", FileNameJoin@{dir, "docs"}];
    If[oldSite=!=pacletSite,
      siteMZ=
        PacletExecute["BundleSite", 
          pacletSite,
          dir,
          "BuildExtension"->Nothing,
          "ExcludedElements"->{"Resources"}
          ];
      CopyFile[siteMZ, 
        FileNameJoin@{dir, "docs", "PacletSite.mz"},
        OverwriteTarget->True
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*AddPaclets*)



Options[AddPaclets]=
  Options[PacletServerAdd];
AddPaclets[ops:OptionsPattern[]]:=
  {
    BuildPacletSite[ops],
    #
    }&@
    Map[
      Function[
        With[
          {
            psa=
              PacletServerAdd[$Paclets, #, 
                FilterRules[{ops}, Options[PacletServerAdd]]
                ]
              },
          CopyFile[#, 
            FileNameJoin@{$BuildDir, "last_build", FileNameTake[#]},
            OverwriteTarget->True
            ]->
            (
              If[DirectoryQ@#, DeleteDirectory[#, DeleteContents->True], DeleteFile[#]];
              psa
              )
            ]
        ],
      Join[
        PacletExecute["AutoGeneratePaclet", #]&/@
          Select[
            FileExistsQ[FileNameJoin[{#, "PacletInfo.m"}]]||
            FileExistsQ[FileNameJoin[{#, FileBaseName[#]<>".m"}]]&
            ]@
            FileNames[
              "*",
              $ReviewQueueDir
              ],
        FileNames[
          "*.paclet",
          $ReviewQueueDir
          ]
        ]
      ]


(* ::Subsubsection::Closed:: *)
(*BuildPages*)



Options[BuildPages]=
  Join[
    Options[PacletServerBuild],
    {
      "ForceBuild"->False
      }
    ]
BuildPages[ops:OptionsPattern[]]:=
  Module[
    {
      dir=$Clone,
      pacs=$Paclets,
      lastB,
      psTime,
      out,
      floppies
      },
    floppies=FilterRules[{ops}, Options@BuildPages];
    If[TrueQ@OptionValue[BuildPages, floppies, "ForceBuild"],
      lastB=None,
      lastB=
        Replace[
          OptionValue[BuildPages, floppies, "LastBuild"],
          {
            Automatic:>
              Lookup[
                Replace[
                  Quiet@Get@FileNameJoin@{dir, "BuildInfo.wl"},
                  Except[_?OptionQ]->{}
                  ],
                "LastBuild",
                None
                ]
            }
          ];
      psTime=FileDate[FileNameJoin@{dir, "PacletSite.mz"}];
      ];
    If[!DateObjectQ[lastB]||(lastB<=psTime),
      out=
        PacletServerBuild[
          dir,
          FilterRules[
            {
              ops,
              "PacletsDirectory"->FileNameJoin@{pacs, "Paclets"}
              }, 
            Options[PacletServerBuild]]
          ];
      CopyFile[
        FileNameJoin@{dir, "PacletSite.mz"},
        FileNameJoin@{out, "PacletSite.mz"},
        OverwriteTarget->True
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*TestServer*)



TestServer[ops:OptionsPattern[]]:=
  PySimpleServerOpen[
    PacletServerExecute["Path", $Clone, "docs"]
    ]


(* ::Subsubsection::Closed:: *)
(*PushGitHub*)



PushServer[ops:OptionsPattern[]]:=
  With[{dir=#},
    Git["Add", dir, "All"->True];
    Git["Commit", 
      dir,
      FilterRules[
        {
          ops,
          "Message"->TemplateApply["Rebuilt on ``", DateString[]],
          "All"->True
          },
        Git["Commit", "Options"]
        ]
      ];
    Pause[.5];
    GitHub["Push", dir]
    ]&/@{$Clone, $Paclets}


End[];



