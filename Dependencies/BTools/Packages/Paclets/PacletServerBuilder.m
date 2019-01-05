(* ::Package:: *)

(* Autogenerated Package *)

(* ::Subsubsection::Closed:: *)
(*PacletServerExecute*)



$PacletServers::usage=
    "The listing of possible servers";
$PacletServer::usage=
  "The configuration for the default paclet server";
PacletServerExecute::usage=
  "Runs functions on a paclet server";


(* ::Subsubsection::Closed:: *)
(*Add / Remove*)



PacletServerAdd::usage=
  "Adds a paclet to the default server";
PacletServerRemove::usage=
  "Removes a paclet from the default server";


PacletServerBuild::usage="Builds a paclet server and site";
PacletServerDeploy::usage="Deploys a paclet server";


PacletServerInterface::usage=
  "Generates an interface listing what's on a paclet server with install buttons"


Begin["`Private`"];


(* ::Subsection:: *)
(*Server Basics*)



(* ::Subsubsection::Closed:: *)
(*patternHack*)



pacletUploadPat=((_String|_URL|_File|{_String,_String}|_Paclet)|
  (_String|_Paclet->_String|_URL|_File|{_String,_String}|_Paclet))|
  {((_String|_URL|_File|{_String,_String}|_Paclet)|
      (_String|_Paclet->_String|_URL|_File|{_String,_String}|_Paclet))..};


LocalPacletServerPattern=
  KeyValuePattern[{
    "ServerBase"->
      (
        _String?DirectoryQ|
        _String?(MatchQ[URLParse[#, "Scheme"], "file"|"http"]&)
        ),
    "ServerName"->_
    }];


localPacletServerPatOrDir=
  LocalPacletServerPattern|_String?DirectoryQ;
localPacletServer=
  MatchQ[LocalPacletServerPattern]


(* ::Subsubsection::Closed:: *)
(*Setup*)



If[!AssociationQ@$PacletServers,
  LoadPacletServers[]
  ]


$PacletServer:=
  PacletServer[$DefaultPacletServer]


(* ::Subsubsection::Closed:: *)
(*PacletServerExecute*)



PacletServerExecute//Clear


$PacletServerExecuteFunctions=
  <|
    "URL"->
      PacletServerURL,
    "DeploymentURL"->
      PacletServerDeploymentURL,
    "Directory"->
      PacletServerDirectory,
    "Path"->
      PacletServerFile,
    "ExposedPaclets"->
      PacletServerExposedPaclets,
    "Dataset"->
      PacletServerDataset,
    "BundleSite"->
      PacletServerBundleSite
    |>;
PacletServerExecute[
  k_?(KeyExistsQ[$PacletServerExecuteFunctions, #]&),
  server:localPacletServerPatOrDir,
  args___
  ]:=
  With[{fn=$PacletServerExecuteFunctions[k]},
    With[{res=fn[server, args]},
      res/;Head[res]=!=fn
      ]
    ];
PacletServerExecute[
  k_?(KeyExistsQ[$PacletServerExecuteFunctions, #]&),
  s_String?(KeyExistsQ[$PacletServers, #]&),
  args___
  ]:=
  With[{r=PacletServerExecute[k, $PacletServers[s], args]},
    r/;Head[r]=!=PacletServerExecute
    ];


PackageAddAutocompletions[
  "PacletServerExecute",
  {
    Keys@$PacletServerExecuteFunctions,
    Keys@$PacletServers
    }
  ]


(* ::Subsection:: *)
(*PacletServerInterface*)



(* ::Subsubsection::Closed:: *)
(*pacletServerInterfacePage*)



pacletServerInterfacePage[
  var_,
  site_,
  coreAssoc_,
  pacletFindData_
  ]:=
  With[{
    name=coreAssoc["Name"],
    version=coreAssoc["Version"],
    creator=Lookup[coreAssoc, "Creator", ""],
    description=Lookup[coreAssoc,"Description",""],
    extensions=
      Replace[
        Lookup[coreAssoc,"Extensions",Nothing],
        ds_Association:>Dataset[ds]
        ]
    },
    Grid[{
      {
        Item[
          Row@{Style[name, Bold],Style[" v"<>version,Gray]},
          Background->GrayLevel[.8],
          Alignment->Center,
          ItemSize->{Automatic, 2},
          FrameStyle->Black
          ],
          SpanFromLeft
        },
      {
        Item[#, Alignment->Left]&@
        Row@{Style["Creator: ",Gray], 
          Replace[Interpreter["EmailAddress"][creator],{
            s_String?(StringLength[#]>0&):>
              Hyperlink[creator, "mailto:"<>creator],
            _->creator
            }]},
        SpanFromLeft
        },
      {
        TextCell[description,
          CellSize->{500,Automatic},
          ParagraphIndent->None,
          Editable->False,
          Selectable->True
          ],
        SpanFromLeft
        },
      {
        Item[
          "Extensions",
          Alignment->Center,
          Background->GrayLevel[.98]
          ],
        SpanFromLeft
        },
      {
        Item[#, Alignment->Left]&@
        Grid[
          KeyValueMap[
            {
              Style[Row[{#, ": "}], Gray],
              Which[
                MatchQ[#2, <||>|<|Prepend->True|>],
                  Grid[{{},{"Enabled"}}, Alignment->{Left, Top}],
                AssociationQ@#2,
                  Grid[
                    Prepend[{}]@
                    KeyValueMap[
                      {
                        Style[Row[{#, ": "}], Gray],
                        #2
                        }&,
                      DeleteDuplicates@#2
                      ],
                    Alignment->{Left, Top}
                    ],
                True,
                  #2
                ]
              }&,
            Normal@extensions
            ],
          Alignment->{Left, Top}
          ],
        SpanFromLeft
        },
      {
        Item[
          Button[Hyperlink@"\[ReturnIndicator]",
            var=Automatic,
            Appearance->None,
            BaseStyle->"Hyperlink"
            ],
          Alignment->Left,
          Background->GrayLevel[.95]
          ],
        Item[
          Dynamic[
            refreshFlag;
            If[Length[PacletManager`PacletFind[name]]==0,
              Button["Install",
                PacletManager`PacletInstall[name,
                  "Site"->site
                  ];
                refreshFlag=RandomReal[],
                Enabled->StringQ[site],
                ImageSize->160,
                Method->"Queued"
                ],
              Grid[
                {
                  {
                    Button["Update",
                      PacletManager`PacletUpdate[name,
                        "Site"->site,
                        "UpdateSites"->False
                        ];
                      refreshFlag=RandomReal[],
                      Enabled->
                        StringQ[site]&&
                        AllTrue[
                          ToExpression/@
                            StringSplit[Lookup[pacletFindData,"Version"],"."],
                          !OrderedQ[
                            ToExpression@StringSplit[coreAssoc["Version"],"."],
                            #
                            ]&
                          ],
                      ImageSize->80,
                      Appearance->"AbuttingRight"
                      ],
                    Button["Uninstall",
                      PacletManager`PacletUninstall[name];
                      refreshFlag=RandomReal[],
                      ImageSize->80,
                      Appearance->"AbuttingLeft"
                      ]
                    }
                  },
                Spacings->{.1,0},
                Dividers->{{2->GrayLevel[.8]}, {}}
                ]
              ],
            TrackedSymbols:>{refreshFlag}
            ],
          Alignment->Right
          ]
        }
      },
      BaseStyle->"Text",
      Frame->True,
      FrameStyle->GrayLevel[.8],
      Dividers->{
        Automatic, 
        {
          1->Black,
          2->GrayLevel[.4],
          3->GrayLevel[.8],
          4->GrayLevel[.8],
          5->GrayLevel[.8],
          6->GrayLevel[.4]
          }
        },
      Background->{{-1->GrayLevel[.98]}}
      ]
    ];
pacletServerInterfacePage~SetAttributes~HoldFirst


(* ::Subsubsection::Closed:: *)
(*pacletServerInterfaceEntry*)



pacletServerInterfaceEntry[
  var_,
  site_,
  coreAssoc_,
  pacletFindData_
  ]:=
  With[{
    name=coreAssoc["Name"],
    version=coreAssoc["Version"],
    creator=Lookup[coreAssoc, "Creator", ""],
    description=Lookup[coreAssoc,"Description",""],
    page=
      pacletServerInterfacePage[var,site,coreAssoc,pacletFindData]
    },
    {
      (* Name *)
      Button[
        Hyperlink@name,
        var=page,
        Appearance->None,
        BaseStyle->"Hyperlink"
        ],
      (* Version *)
      Row@{"v",version},
      (* Creator *)
      creator,
      (* Update / Install *)
      Dynamic[
        refreshFlag;
        If[Length[PacletManager`PacletFind[name]]===0,
          Button["Install",
            PacletManager`PacletInstall[name,"Site"->site];
            refreshFlag=RandomReal[],
            ImageSize->160,
            Method->"Queued"
            ],
          Grid[
            {
              {
                Button["Update",
                  PacletManager`PacletUpdate[name,
                    "Site"->site,
                    "UpdateSites"->False
                    ];
                  refreshFlag=RandomReal[],
                  ImageSize->80,
                  Enabled->
                    StringQ[site]&&
                      AllTrue[
                        ToExpression/@
                          StringSplit[Lookup[pacletFindData,"Version"],"."],
                        !OrderedQ[
                          ToExpression@StringSplit[coreAssoc["Version"],"."],
                          #
                          ]&
                        ],
                  Appearance->"AbuttingRight"
                  ],
                Button["Uninstall",
                  PacletManager`PacletUninstall[name];
                  refreshFlag=RandomReal[],
                  Appearance->"AbuttingLeft",
                  ImageSize->80
                  ]
                }
              },
            Spacings->{.1,0},
            Dividers->{{2->GrayLevel[.8]}, {}}
            ]
          ],
        TrackedSymbols:>{refreshFlag}
        ]
      }
    ];
pacletServerInterfaceEntry~SetAttributes~HoldFirst;


(* ::Subsubsection::Closed:: *)
(*PacletServerInterface*)



PacletServerInterface//Clear


Options[PacletServerInterface]=
  Join[
    Options[Pane],
    Options[Grid]
    ];
PacletServerInterface[
  siteBase:_String|_?OptionQ|None:None,
  siteDS_Dataset,
  displayStart:Except[_?OptionQ]:Automatic,
  ops:OptionsPattern[]
  ]:=  
  With[{
    ds=
      DeleteDuplicatesBy[#["Name"]&]@
      SortBy[
        {
          Lookup[#,"Name"],
          100000+-ToExpression@StringSplit[Lookup[#, "Version", "1.0.0"],"."]
          }&
        ]@Normal@siteDS,
    site=
      Replace[siteBase,
        o_?OptionQ:>
          PacletServerURL[o]
        ]
    },
    DynamicModule[{
      main,
      display
      },
      display=
        If[StringQ@displayStart,
          With[{pf=PacletManager`PacletFind[displayStart]},
            If[Length@pf>0,
              pacletServerInterfacePage[
                display,
                siteDS,
                PacletInfoAssociation@
                  pf[[1]],
                PacletInfoAssociation/@
                  pf
                ],
              Automatic
              ]
            ],
          Automatic
          ];
      main=
        Pane[
          Grid[
            Prepend[
              Map[
                Item[
                  Style[#, Bold],
                  FrameStyle->Black,
                  Alignment->{Left, Center},
                  ItemSize->{Automatic, 2}
                  ]&,
                {"Name", "Version", "Creator", "Install"}
                ]
              ]@
            Map[
              pacletServerInterfaceEntry[
                display,
                site,
                #,
                PacletInfoAssociation/@
                  PacletManager`PacletFind[#["Name"]]
                ]&,
              ds
              ],
            FilterRules[
              {
                ops,
                Background->
                  {
                    Automatic,
                    Prepend[GrayLevel[.8]]@
                      Flatten@ConstantArray[{White,GrayLevel[.95]},Length[ds]]
                    },
                Frame->True,
                FrameStyle->GrayLevel[.8],
                Dividers->{
                  Flatten@
                    {
                      Table[n+1->GrayLevel[.9],{n,3}]
                      },
                  Flatten@{
                    Table[1+n->GrayLevel[.8],{n,Length[ds]-1}]
                    }
                  },
                BaseStyle->"Text",
                Alignment->Left
                },
              Options[Grid]
              ]
            ],
        FilterRules[{ops},
          Alternatives@@
            Complement[Keys[Options[Pane]],
              Keys@Options[Grid]
              ]
          ]
        ];
      Dynamic[
        Replace[display,Automatic:>main],
        None
        ]
      ]
    ];
PacletServerInterface[
  site:_String|_?OptionQ|Automatic:Automatic, 
  display:Except[_?OptionQ]:Automatic,
  ops:OptionsPattern[]
  ]:=
  With[
    {s=
      Replace[site,
        {
          Automatic:>
            PacletServerURL[
              With[{
                f=
                  FilterRules[
                    {ops},
                    Except[Alternatives@@Join[Keys@Options[Grid], Keys@Options[Pane]]]
                    ]
                },
                If[Length@f>0,
                  f,
                  $PacletServer
                  ]
                ]
              ],
          o_?OptionQ:>
            PacletServerURL[o]
          }
        ]
      },
    PacletServerInterface[
      s,
      PacletSiteInfoDataset[s],
      display,
      ops
      ]
    ]


(* ::Subsection:: *)
(*Sites Layout*)



(*

The server structure looks like this:
	
	PacletServer
	
	   + Paclets
	   - PacletSite.mz
	   + content
	      + posts
	        - paclet1.nb
	        - paclet1.md
	        - paclet2.nb
	        - paclet2.md
	        ...
	      + pages
	        - about.md (??)
	        
	   - SiteConfig.m

When the server is built the Paclets and PacletSite.mz are copied to output for deployment

*)


(* ::Subsection:: *)
(*Single Page*)



(* ::Subsubsection::Closed:: *)
(*Config*)



$PacletServerTitle="Paclet Server";
$PacletServerDescription="";


(* ::Subsubsection::Closed:: *)
(*pacletDownloadLine*)



pacletDownloadLine[
  pacletDownloadNB_,
  pacletDownloadURL_
  ]:=
  XMLElement["div",
    {
      "class"->"paclet-download-line"
      },
    {
      XMLElement["a",
        {
          "href"->"wolfram+cloudobject:"<>pacletDownloadNB
          },
        {
          "Notebook"
          }
        ],
      " | ",
      XMLElement["a",
        {
          "href"->pacletDownloadURL
          },
        {
          "Paclet"  
          }
        ]
      }
    ];


(* ::Subsubsection::Closed:: *)
(*pacletSectionXML*)



Options[pacletSectionXML]=
  Options[PacletInfoExpression];
pacletSectionXML[site_,ops:OptionsPattern[]]:=
  XMLElement["div",
    {
      "class"->"paclet-section",
      "id"->OptionValue["Name"]
      },
    {
      XMLElement["h3",
        {
          "class"->"paclet-name"
          },
        {
          OptionValue["Name"],
          XMLElement["span",
            {
              "class"->"paclet-version-text"
              },
            {
              " v"<>OptionValue["Version"],
              Replace[
                Replace[OptionValue["WolframVersion"],
                  Except[_String]:>OptionValue["MathematicaVersion"]
                  ],{
                s_String:>
                  " | Mathematica "<>s,
                _->Nothing
                }]
              }
            ]
        }],
      XMLElement["div",
        {
          "class"->"paclet-section-box"
          },
        {
          pacletDownloadLine[
            URLBuild[{
              site,
              OptionValue["Name"]<>"-"<>
                OptionValue["Version"]<>".nb"
              }],
            URLBuild[{
              site,
              "Paclets",
              OptionValue["Name"]<>"-"<>
                OptionValue["Version"]<>".paclet"
              }]
            ],
          XMLElement[
            "p",
            {
              "class"->"paclet-download-description"  
              },
            {
              Replace[
                OptionValue["Description"],
                Automatic->""
                ]
              }
            ]
          }
        ]
      }
    ];


(* ::Subsubsection::Closed:: *)
(*$pacletServerCSS*)



$pacletServerCSS=
"
body { 
	background: #fafafa ;
	margin: 0;
	}
.paclet-server-title {
	width: 100%;
	margin: 0;
	padding: 10;
	left: 0;
	top: 0;
	border-bottom: 1px solid #b01919 ;
	background: #8f3939; 
	color: #fafafa;
	box-shadow: 0px 2px 2px #901919 ;
 }
.paclet-server-description { 
	color: #505050;
	margin-left: 20px;
 }
.paclet-section {
	margin-top: 25;
	margin-left: 20px;
	width: 95%;
	margin-bottom: 15px;
	box-shadow: 1px 1px 1px gray ;
	border-radius: 5px;
	}
.paclet-name {
	min-height: 25px;
	margin: 0;
	padding: 10;
	color: #fafafa;
	background: #3f3f3f;
	border: solid 1px #3f3f3f;
	box-shadow: 1px 2px 2px #5f5f5f;
	border-top-left-radius: 5px;
	border-top-right-radius: 5px;
	}
.paclet-section-box { 
	border-left: solid 1px gray;
	border-right: solid 1px gray;
	border-bottom: solid 1px gray;
	border-bottom-left-radius: 5px;
	border-bottom-right-radius: 5px; 
	background: #f6f6f6;
	margin: 0;
	margin-top: 2;
	padding: 10;
	min-height: 125px;
 }
.paclet-version-text { 
	color: gray; 
	}
a:link {
	color: gray;
	}
a:hover {
	color: #cf3939;
	}
a:visited {
	color: #8f3939;
	}
";


(* ::Subsubsection::Closed:: *)
(*pacletServerXML*)



Options[pacletServerXML]={
  "Title"->Automatic,
  "Description"->Automatic
  };
pacletServerXML[
  site_,
  pacletSpecs:_Association|{___Association},
  ops:OptionsPattern[]
  ]:=
  XMLElement["html",{},{
    XMLElement["head",{},
      {
        XMLElement["title",{},{
          Replace[
            Replace[OptionValue["Title"],
              Automatic|Default->$PacletServerTitle
              ],
            Except[_String]->""
            ]
          }],
        XMLElement["style",
          {},
          {
            $pacletServerCSS
            }
          ]
    }],
    XMLElement["body",
      {},
      Flatten@{
        XMLElement["div",
          {
            "class"->"paclet-server-title"
            },
          {
            XMLElement["h2",{},{
              Replace[
                Replace[OptionValue["Title"],
                  Automatic|Default->$PacletServerTitle
                  ],
                Except[_String]->""
                ]
              }]
            }
          ],
        XMLElement[
          "div",
          {
            "class"->"paclet-server-description"
            },
          {
            XMLElement["p",{},{
              Replace[
                Replace[OptionValue["Description"],
                  Automatic|Default->$PacletServerDescription
                  ],
                Except[_String]->""
                ]
              }]
            }
          ],
        pacletSectionXML[site,#]&/@
          PacletServerExposedPaclets[pacletSpecs]
        }
      ]
    }];


(* ::Subsubsection::Closed:: *)
(*PacletServerPage*)



Options[PacletServerPage]=
  Join[{
    Permissions->Automatic
    },
    Options[CloudExport],
    Options[PacletSiteURL],
    Options[pacletServerXML],{
    "Extension"->""
    }];
PacletServerPage[
  ops:OptionsPattern[]
  ]:=
  Block[{
    pacletServer=
      PacletSiteURL[FilterRules[{ops},Options@PacletSiteURL]],
    pacletServerPageXML:=
      htmlExportString@
        pacletServerXML[
          pacletServer,
          Normal@PacletSiteInfoDataset[pacletServer],
          FilterRules[{ops},Options@pacletServerXML]
          ]
    },
    If[StringStartsQ[pacletServer,"file:"],
      Export[
        FileNameJoin@
          Append[
            URLParse[pacletServer,"Path"],
            OptionValue@"Extension"
            ],
        pacletServerPageXML,
        "Text"
        ],
      CloudExport[
        HTMLTemplateNotebook;
        pacletServerPageXML,
        "HTML",
        URLBuild@{
          pacletServer,
          OptionValue@"Extension"
          },
        FilterRules[{
          ops,
          Permissions->pacletStandardServerPermissions@OptionValue[Permissions]
          },
          Options@CloudExport]
        ]
      ]
  ]


(* ::Subsection:: *)
(*Add / Remove*)



(* ::Subsubsection::Closed:: *)
(*PacletServerAdd*)



PacletServerAdd//Clear


Options[PacletServerAdd]=
  Options@PacletUpload;
PacletServerAdd[
  server:LocalPacletServerPattern,
  pacletSpecs:pacletUploadPat,
  ops:OptionsPattern[]
  ]:=
  PacletUpload[
    pacletSpecs,
    ops,
    Sequence@@
      FilterRules[
        Normal@server,
        Options@PacletUpload
        ],
    "UseCachedPaclets"->False,
    "UploadSiteFile"->True
    ];
PacletServerAdd[
  k_?(KeyMemberQ[$PacletServers, #]&),
  pacletSpecs:pacletUploadPat,
  ops:OptionsPattern[]
  ]:=
  With[{s=
    PacletServerAdd[
      $PacletServers[k],
      pacletSpecs,
      ops
      ]
    },
    s/;Head[s]=!=PacletServerAdd
    ];
PacletServerAdd[
  s_String?DirectoryQ,
  pacletSpecs:pacletUploadPat,
  ops:OptionsPattern[]
  ]:=
  PacletServerAdd[
    {"ServerBase"->s, "ServerName"->Nothing},
    pacletSpecs,
    ops
    ]


(* ::Subsubsection::Closed:: *)
(*PacletServerRemove*)



PacletServerRemove//Clear


Options[PacletServerRemove]=
  Options@PacletRemove;
PacletServerRemove[
  server:LocalPacletServerPattern,
  pacletSpecs:$PacletRemovePatterns,
  ops:OptionsPattern[]
  ]:=
  PacletRemove[
    pacletSpecs,
    Sequence@@
      FilterRules[
        Flatten@{
          ops,
          "MergePacletInfo"->False,
          Normal@server
          },
        Options@PacletRemove
        ]
    ];
PacletServerRemove[
  k_?(KeyMemberQ[$PacletServers, #]&),
  pacletSpecs:$PacletRemovePatterns,
  ops:OptionsPattern[]
  ]:=
  With[{
    s=
    PacletServerRemove[
      $PacletServers[k],
      pacletSpecs,
      ops
      ]
    },
    s/;Head[s]=!=PacletServerRemove
    ];
PacletServerRemove[
  s_String?DirectoryQ,
  pacletSpecs:pacletUploadPat,
  ops:OptionsPattern[]
  ]:=
  PacletServerRemove[
    {"ServerBase"->s, "ServerName"->Nothing},
    pacletSpecs,
    ops
    ]


(* ::Subsubsection::Closed:: *)
(*PacletServerDelete*)



Options[PacletServerDelete]=
  {
    "DeleteLocal"->True,
    "DeleteCloud"->False
    };
PacletServerDelete[
  server:LocalPacletServerPattern,
  ops:OptionsPattern[]
  ]:=
  (
    If[OptionValue["DeleteLocal"],
      With[{d=PacletServerDirectory[server]},
        If[DirectoryQ[d],
          DeleteDirectory[PacletServerDirectory[server],
            DeleteContents->True
            ]
          ]
        ]
      ];
    If[OptionValue["DeleteCloud"],  
      With[
        {d=
          Quiet@Check[
            CloudObject@PacletServerDeploymentURL[server], 
            $Failed
            ]},
        If[MatchQ[d, _CloudObject],
          Quiet[
            DeleteFile/@
              Replace[CloudObjects[d], Except[{__CloudObject}]->{}]
            ]
          ]
        ]
      ];
    )
PacletServerDelete[
  k_?(KeyMemberQ[$PacletServers, #]&),
  ops:OptionsPattern[]
  ]:=
  PacletServerDelete[$PacletServers[k], ops]


(* ::Subsection:: *)
(*Site*)



(* ::Subsubsection::Closed:: *)
(*PacletServerBuild*)



(* ::Subsubsubsection::Closed:: *)
(*getServerConfigOptions*)



getServerConfigOptions[server_, confFile_, confOps_]:=
  Module[{conf},
    conf = 
      Join[
        Replace[
          Replace[confFile,
            {
              fname_String?(FileExistsQ[PacletServerFile[server, #]]&):>
                PacletServerFile[server, fname],
              Except[_String?FileExistsQ]:>
                If[FileExistsQ@PacletServerFile[server, "SiteConfig.m"],
                  PacletServerFile[server, "SiteConfig.m"],
                  PacletServerFile[server, "SiteConfig.wl"]
                  ]
              }
            ],
          {
              f_String?FileExistsQ:>
                Replace[Import[f], {o_?OptionQ:>Association[o],_-><||>}],
              _-><||>
            }],
        Replace[Normal@confOps,
          {
            o_?OptionQ:>Association@o,
            _-><||>
            }
          ]
        ];
      If[StringQ@server,
        conf,
        Join[
          <|
            "SiteName"->
              Lookup[server, "ServerName"],
            "SiteURL"->
              With[
                {
                  cc=
                    StringReplace[
                      PacletServerDeploymentURL[server],
                      "http://"->"https://"
                      ]
                  },
                cc
                ],
            "Theme"->
              "PacletServer",
            CloudConnect->
              Lookup[server, CloudConnect],
            Permissions->
              Lookup[server, Permissions]
            |>,
          conf
          ]
        ]
      ]


(* ::Subsubsubsection::Closed:: *)
(*PacletServerBuild*)



Options[PacletServerBuild]=
  Normal@
    Merge[
      Join[
        Options[WebSiteBuild],
        {
          "RegenerateContent"->Automatic,
          "BuildSite"->True,
          "GenerateSearchPage"->Automatic
          },
        {
          "PacletsDirectory"->Automatic
          }
        ],
      Last
      ];
PacletServerBuild[
  server:localPacletServerPatOrDir,
  ops:OptionsPattern[]
  ]:=
  Block[
    {
      $BuildingPacletServerDirectory=
        PacletServerDirectory[server]
      },
    Module[
      {
        siteData=
          PacletServerExposedPaclets[server],
        servDir=
          Replace[server, 
            Except[_String?DirectoryQ]:>
              PacletServerDirectory[server]
            ],
        pacsDir=
          OptionValue["PacletsDirectory"],
        tmp, s,
        serverOutDirectory
        },
      PacletServerInitialize[server];
      pacsDir=
        Replace[pacsDir, 
          Except[_String?DirectoryQ]:>
            PacletServerFile[server, {"Paclets"}]
          ];
      If[MatchQ[OptionValue["RegenerateContent"], True|Automatic],
         RegeneratePacletPages[server, servDir, pacsDir, siteData, 
           OptionValue[Monitor], OptionValue["RegenerateContent"]
           ]
        ];
      (* Basic site building procedure *)
      s=
        If[TrueQ@OptionValue["BuildSite"],
          WebSiteBuild[
            PacletServerDirectory[server],
            "AutoDeploy"->False,  
            "ConfigurationFile"->
              None,
            "ConfigurationOptions"->
              getServerConfigOptions[server,
                OptionValue["ConfigurationFile"], OptionValue["ConfigurationOptions"]
                ],
            Sequence@@
              FilterRules[
                FilterRules[
                  {
                    ops,
                    "OutputDirectory"->
                      If[GitRepoQ@PacletServerDirectory[server],
                        "docs",
                        Automatic
                        ],
                    "GenerateSearchPage"->Automatic
                    },
                  Options@WebSiteBuild
                  ],
                Except["AutoDeploy"]
                ]
            ],
          serverOutDirectory=
            PacletServerFile[
              server,
              If[GitRepoQ@PacletServerDirectory[server],
                 "output",
                 "docs"
                  ]
              ];
          Quiet@CreateDirectory@serverOutDirectory;
          serverOutDirectory
          ];
        If[TrueQ[OptionValue["AutoDeploy"]]||
          TrueQ@
            OptionValue["AutoDeploy"]===Automatic&&
              Lookup[
                Replace[Quiet@Import[PacletServerFile[server, "SiteConfig.wl"]],
                  Except[_Association]:>{}
                  ],
                "AutoDeploy"
                ],
          PacletServerDeploy[
            server,
            Replace[
              OptionValue["DeployOptions"],
              Except[_?OptionQ]->{}
              ]
            ],
          s
          ]
      ]
    ];
PacletServerBuild[
  k_?(KeyMemberQ[$PacletServers, #]&),
  ops:OptionsPattern[]
  ]:=
  PacletServerBuild[$PacletServers[k], ops]


(* ::Subsubsection::Closed:: *)
(*PacletServerDeploy*)



PacletServerDeploy//Clear


PacletServerDeploy::nobld=
  "PacletServerBuild needs to be called before PacletServerDeploy can work";


Options[PacletServerDeploy]=
  Join[
    Options[WebSiteDeploy],
    {
      "DeployPages"->True
      }
    ];
PacletServerDeploy[
  server:LocalPacletServerPattern,
  ops:OptionsPattern[]
  ]:=
  With[
    {
      outDir=
        Replace[OptionValue["OutputDirectory"],
            {
              Automatic:>
                PacletServerFile[server, "output"],
              s_String?(Not@*DirectoryQ):>
                PacletServerFile[server, s]
              }
            ]
      },
    If[
      DirectoryQ@PacletServerFile[server, "Paclets"]||
        DirectoryQ@outDir,
      With[
        {
          baseConfig=
            Lookup[
              Replace[Quiet@Import[PacletServerFile[server, "SiteConfig.wl"]],
                Except[_?OptionQ]:>{}
                ],
              "DeployOptions",
              {}
              ]
          },
          If[!DirectoryQ@#,
            CreateDirectory@#
            ]&@outDir;
          WebSiteDeploy[
            outDir,
            Lookup[server, "ServerName"],
            FilterRules[
              Normal@
                Merge[
                  {
                    ops,
                    CloudConnect->
                      Lookup[server, CloudConnect],
                    Permissions->
                      Lookup[server, Permissions],
                    baseConfig,
                    "ServerTheme"->
                      "PacletServer",
                    "ExtraFileNameForms"->
                      {
                        "PacletSite.mz",
                        "*.paclet"
                        },
                    "IncludeFiles"->
                      {
                        PacletServerFile[server, "PacletSite.mz"],
                        PacletServerFile[server, "Paclets"]
                        },
                    "OutputDirectory"->
                      If[GitRepoQ@PacletServerDirectory[server],
                        "docs",
                        Automatic
                        ]
                      },
                  Replace[
                    {
                      {s:_String|_?OptionQ|_?AtomQ,___}:>s,
                      e_:>Flatten@e
                      }
                    ]
                  ],
              Options@WebSiteDeploy
              ]
            ]
        ],
      Message[PacletServerDeploy::nobld];
      $Failed
      ]
    ];
PacletServerDeploy[
  k_?(KeyMemberQ[$PacletServers, #]&),
  ops:OptionsPattern[]
  ]:=
  PacletServerDeploy[$PacletServers[k], ops]


(* ::Subsection:: *)
(*Git*)



(* ::Subsubsection::Closed:: *)
(*PacletServerGitHubRepoExists*)



PacletServerGitHubRepoExistsQ[server_]:=
  With[{repo=PacletServerGitHubRepo[server]},
    Between[URLRead[repo,"StatusCode"], {200,299}]
    ]


(* ::Subsubsection::Closed:: *)
(*PacletServerGitHubRepo*)



PacletServerGitHubRepo[server_, password_:None]:=
  Replace[
    Replace[
      Lookup[server, "GitHubRepo"],
      Except[_String?(StringLength[#]>0&)]:>
        Lookup[server, "ServerName"]
      ],
    s_String:>
      URL@
        GitHubPath[
          s,
          "Password"->password
          ]
    ]


(* ::Subsubsection::Closed:: *)
(*PacletServerGitHubConfigure*)



$PacletServerDefaultREADMEText="
### Paclet Server 

## About

This is a Mathematica paclet server.

It hosts paclets that can be installed directly into Mathematica.

## Installation:

To install a paclet, use the following:

    PacletInstall[\"paclet_name\",
     \"Site\"->\"http://raw.githubusercontent.com/<user_name>/<repo_name>\"
     ]

To update a paclet, use the following:

    PacletUpdate[\"paclet_name\",
     \"Site\"->\"http://raw.githubusercontent.com/<user_name>/<repo_name>\"
     ]

";


$PacletServerREADMEText:=
  $PacletServerREADMEText=
    Replace[
      Quiet@
        Import[
          PackageFilePath["Resources", "Templates", "PacletServer-README.md"],
          "Text"
          ],
      Except[_String]->
        $PacletServerDefaultREADMEText
      ];


PacletServerGitHubConfigure[server_]:=
  (
    If[!FileExistsQ@PacletServerFile[server, "README.md"],
      Export[PacletServerFile[server, "README.md"],
        $PacletServerREADMEText,
        "Text"
        ]
      ];
    GitHub["Configure",
      PacletServerDirectory[server],
      PacletServerGitHubRepo[server],
      {".DS_Store"},
      {"content"}
      ]
    )


(* ::Subsubsection::Closed:: *)
(*PacletServerGitHubPush*)



PacletServerGitHubPush[server_]:=
  With[{dir=PacletServerDirectory[server]},
    Git["Add", dir, "-A"];
    Git["Commit", dir, 
      Message->
        TemplateApply[
          "Committed paclet server @ ``",
          StringReplace[
            DateString["ISODateTime"],
            "T"->"_"
            ]
          ]
      ];
    GitHubImport["Push", dir]
    ]


End[];


