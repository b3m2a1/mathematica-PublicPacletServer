(* ::Package:: *)



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



UpdateQueue[ops:OptionsPattern[]]:=
  Module[
    {
      dir=$Clone,
      log,
      logMerge,
      extras,
      extrasString,
      pacletLastTime,
      pacletUpdateRate,
      pacletUpdateFlag,
      paclet
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
      Table[
        pacletUpdateRate=Lookup[e, "Update", "DownloadOnce"];
        Which[
          pacletUpdateRate=="DownloadNever",
            pacletUpdateFlag=False,
          pacletUpdateRate=="DownloadOnce",
            e["Update"]="DownloadNever";
            pacletUpdateFlag=True,
          pacletUpdateRate=="DownloadAlways",
            pacletUpdateFlag=True,
          QuantityQ@pacletUpdateRate,
            pacletUpdateFlag=
              TrueQ[(Now-logMerge["Date"])>pacletUpdateRate]
          ];
        If[pacletUpdateFlag,
          Which[
            KeyExistsQ[e, "Site"], 
              paclet=
                PacletExecute[
                "Download", 
                  e["Name"],
                  "Site"->e["Site"]
                  ],
            KeyExistsQ[e, "URL"],
              paclet=PacletExecute["Download", e["URL"]],
            True,
              paclet=$Failed
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
            ]
          ];
        e,
        {e, extras}
        ];
    PrettyExport[
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
(*AddPaclets*)



Options[AddPaclets]=
  Options[PacletServerAdd];
AddPaclets[ops:OptionsPattern[]]:=
  Function[PacletManager`Package`BuildPacletSiteFiles[$Clone];#]@
    Map[
      Function[
        With[{psa=
          PacletServerAdd[$Clone, #, 
            FilterRules[{ops}, Options[PacletServerAdd]]
            ]},
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
  Options[PacletServerBuild];
BuildPages[ops:OptionsPattern[]]:=
  PacletServerBuild[$Clone,
   FilterRules[{ops}, Options[PacletServerBuild]]
   ];


(* ::Subsubsection::Closed:: *)
(*TestServer*)



TestServer[ops:OptionsPattern[]]:=
  PySimpleServerOpen[
    PacletServerExecute["Path", $Clone, "docs"]
    ]


(* ::Subsubsection::Closed:: *)
(*PushGitHub*)



PushServer[ops:OptionsPattern[]]:=
  With[{dir=$Clone},
    Git["Add", $Clone, "All"->True];
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
    ];


End[];



