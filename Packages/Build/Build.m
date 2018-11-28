(* ::Package:: *)

(* Autogenerated Package *)

RebuildServer::usage="Rebuilds the site in entirety";


Begin["`Private`"];


PublicPacletServer; (* invoke the autoloader *)


PublicPacletServer::badbld=
  "Local version of the server needed before building. \
Call PublicPacletServer[\"Clone\"] first.";


$ServerRebuildKeys=
  "UpdateQueue"|"Log"|"Add"|"Build"|"Push"|"Test";


RebuildServer[do:{$ServerRebuildKeys..}:
  {
    "UpdateQueue", "Add", 
    "Log", "Build",
    "Push"
    },
  ops:OptionsPattern[]
  ]:=
  If[StringQ@$Clone&&DirectoryQ@$Clone,
    Block[
      {
        res=<||>
        },
      If[MemberQ[do, "UpdateQueue"],
        Monitor[
          res["UpdateQueue"]=
            UpdateQueue[
              FilterRules[{ops}, Options[UpdateQueue]]
              ],
          Internal`LoadingPanel["Updating review queue..."]
          ]
        ];
      If[MemberQ[do, "Add"],
        Monitor[
          res["Add"]=
            AddPaclets[
              FilterRules[{ops}, Options[AddPaclets]]
              ],
          Internal`LoadingPanel["Adding paclets..."]
          ]
        ];
      If[MemberQ[do, "Log"],
        Monitor[
          res["Log"]=
            BuildLog[
              FilterRules[{ops}, Options[BuildLog]]
              ],
          Internal`LoadingPanel["Building server log..."]
          ]
        ];
      If[MemberQ[do, "Build"],
        Monitor[
          res["Build"]=
            BuildPages[
              FilterRules[{ops}, Options[BuildPages]]
              ],
          Internal`LoadingPanel["Building pages..."]
          ]
        ];
      If[MemberQ[do, "Test"],
        TestServer[]
        ];
      If[MemberQ[do, "Push"],
        Monitor[
          res["Push"]=
            PushServer[
              FilterRules[{ops}, Options[PushServer]]
              ],
          Internal`LoadingPanel["Pushing to GitHub..."]
          ]
        ];
      res
      ],
    Message[PublicPacletServer::badbld];
    $Failed
    ];
RebuildServer[
  do:$ServerRebuildKeys, 
  ops:OptionsPattern[]
  ]:=
  RebuildServer[{do}, ops]


End[];



