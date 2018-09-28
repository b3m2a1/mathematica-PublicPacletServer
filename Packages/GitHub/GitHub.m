(* ::Package:: *)



(* ::Subsubsection::Closed:: *)
(*Forks*)



$CurrentForks::usage=
  "List of current forks of the head repo";
$CurrentRepos::usage=
  "List of current repos of the authenticated user";
LoadForks::usage=
  "";
ForkedQ::usage=
  "Specifies whether the repo has been forked to the current user";
Fork::usage=
  "Forks the paclet server repository";


(* ::Subsubsection::Closed:: *)
(*Clones*)



FindClone::usage=
  "Finds the clone repo";


Clone::usage=
  "NOT IMPLEMENTED;

Performs a shallow clone of the main repo
";


(* ::Subsubsection::Closed:: *)
(*Issues*)



$CurrentIssues::usage=
  "List of current issues of the head repo";
LoadIssues::usage=
  "Loads the issues for the head repo";


Begin["`Private`"];


PublicPacletServer; (* invoke the autoloader *)


(* ::Subsubsection::Closed:: *)
(*Issues*)



(* ::Subsubsubsection::Closed:: *)
(*LoadIssues*)



LoadIssues[]:=
  With[
    {
      res=
        PPSGitHubCheck@
          GitHub["ListIssues", "paclets/PacletServer", "State"->"all",
            "ImportedResult"
            ]
        },
    If[res=!=$Failed,
      $CurrentIssues=res,
      res
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*$CurrentIssues*)



If[Length@OwnValues[$CurrentIssues]==0,
  LoadIssues[]
  ];


(* ::Subsubsection::Closed:: *)
(*Fork*)



(* ::Subsubsubsection::Closed:: *)
(*LoadForks*)



LoadForks[]:=
  With[{res=PPSGitHubCheck@GitHub["ListForks", "paclets/PacletServer"]},
    If[res=!=$Failed,
      $CurrentForks=res,
      res
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*$CurrentForks*)



If[Length@OwnValues[$CurrentForks]==0,
  LoadForks[]
  ];


(* ::Subsubsubsection::Closed:: *)
(*LoadRepos*)



LoadRepos[]:=
  With[
    {
      res=
        PPSGitHubCheck@
          GitHub["ListMyRepositories", "ImportedResult"]
      },
    If[res=!=$Failed,
      $CurrentRepos=res,
      res
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*$CurrentRepos*)



If[Length@OwnValues[$CurrentRepos]==0,
  $CurrentRepos:=LoadRepos[]
  ];


(* ::Subsubsubsection::Closed:: *)
(*ForkedQ*)



ForkedQ[]:=
  MemberQ[
    Lookup[$CurrentForks, "FullName"], 
    Alternatives@@Lookup[$CurrentRepos, "FullName"]
    ];


(* ::Subsubsubsection::Closed:: *)
(*Fork*)



(* ::Text:: *)
(*
	Should first check for whether a fork exists and if not try to fork the repo
*)



PublicPacletServer::nofk=
  "Couldn't fork the public paclet server."


Fork[]:=
  If[!ForkedQ[],
    Monitor[
      Pause[.5];
      With[{res=PPSGitHubCheck@GitHub["Fork", $Repository]},
        If[AssociationQ@res, 
          AppendTo[$CurrentRepos, res];
          AppendTo[$CurrentForks, res];
          ];
        res["FullName"]
        ],
      Internal`LoadingPanel[
        "Forking ``..."~TemplateApply~URL[$Repository]
        ]
      ],
    $Fork
    ]


(* ::Subsubsection::Closed:: *)
(*Clone*)



(* ::Subsubsubsection::Closed:: *)
(*FindClone*)



PublicPacletServer::noclo=
  "No clone of the main repo found";


CheckClone[dir_]:=
  AllTrue[
    {
      "Paclets",
      "PacletSite.mz",
      "ReviewQueue",
      "content",
      "docs",
      ".git"
      },
    FileExistsQ@
      FileNameJoin@{dir, #}&
    ]&&
    With[{rm=Git["GetRemoteURL", dir]},
      StringEndsQ[rm, "PacletServer.git"]&&
        Not[StringEndsQ[rm, "paclets/PacletServer.git"]]
      ]


FindClone[]:=
  Replace[
    SelectFirst[
      Select[
        Join@@
          Map[
            FileNames["*", #]&,
            {
              FileNameJoin@{$UserBaseDirectory, "ApplicationData", $PackageName},
              FileNameJoin@{$UserDocumentsDirectory, "GitHub"},
              FileNameJoin@{$HomeDirectory, "GitHub"}
              }
            ],
        DirectoryQ
        ],
      CheckClone,(*
			Message[PublicPacletServer::noclo];*)
      None
      ],
    s_String?DirectoryQ:>
      Set[$Clone, s]
    ]


(* ::Subsubsubsection::Closed:: *)
(*Clone*)



(* ::Text:: *)
(*
	
	Perform a shallow clone of the repo, pushing it into $UserBaseDirectory/ApplicationData/PublicPacletServer

*)



Clone[]:=
  If[!(StringQ@$Clone&&DirectoryQ@$Clone),
    With[{fk=Fork[]},
      If[StringQ@fk,
        Replace[
          GitHub["Clone",
            fk,
            Quiet@
              CreateDirectory[
                FileNameJoin@{
                  $UserBaseDirectory,
                  "ApplicationData",
                  $PackageName,
                  "PacletServer"
                  },
                CreateIntermediateDirectories->True
                ];
            FileNameJoin@{
              $UserBaseDirectory,
              "ApplicationData",
              $PackageName,
              "PacletServer"
              },
            "Depth"->1,
            OverwriteTarget->True
            ],
          s_String:>
            Set[$Clone, s]
          ],
        $Failed
        ]
      ],
    $Clone
    ]


End[];



