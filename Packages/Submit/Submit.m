(* ::Package:: *)



RegisterPaclet::usage=
  "Registers a paclet via an Issues request";
RequestPacletUpdate::usage=
  "Request a update "


SubmitPaclet::usage=
  "Submits a paclet the review queue in the user's repo";
SubmitPullRequest::usage=
  "Submits a pull request to the main repo";


Begin["`Private`"];


(* ::Subsubsection::Closed:: *)
(*Register*)



pacletRegisterIssueTitle[pacletName_]:=
  "Register paclet: ``"~TemplateApply~pacletName;


(* ::Subsubsubsection::Closed:: *)
(*$registerPacletTemplate*)



$registerPacletTemplate=
"Request to add paclet to server:

     Name:   `Name`
     Author: `Author`
     URL:    `URL`
     Update: `Update`

";


(* ::Subsubsubsection::Closed:: *)
(*RegisterPaclet*)



RegisterPaclet[pacletData_?(AssociationQ[#]&&KeyExistsQ[#, "Name"]&)]:=
  With[
    {
      text=
        TemplateApply[
          $registerPacletTemplate,
          Join[
            <|
              "Author"->
                Function[If[!StringQ@#, "usr", #]]@GitHub["CurrentUser"], 
              "URL"->
                URLBuild@
                  <|
                    "Scheme"->"https",
                    "Domain"->"github.com",
                    "Path"->{
                      Function[If[!StringQ@#, "usr", #]]@GitHub["CurrentUser"],
                      pacletData["Name"]
                      }
                    |>,
              "Update"->"DownloadOnce"
              |>,
            pacletData
            ]
          ]
      },
    If[StringQ@text,
      PPSGitHubCheck@
        GitHub[
          "CreateIssue", 
          $Repository,
          pacletRegisterIssueTitle@pacletData["Name"],
          text
          ],
      $Failed
      ]
    ]


RegisterPaclet[s_String]:=
  RegisterPaclet[
    <|
      "Name"->s
      |>
    ]


(* ::Subsubsubsection::Closed:: *)
(*RequestPacletUpdate*)



$pacletUpdateMessage=
  "Paclet has been updated. Merge of new version requested.";


iRequestPacletUpdate[pacletName_String, retry:True|False:True]:=
  PackageExceptionBlock["GitHub"]@
    (*With[{t="Paclet registration for "<>pacletName},*)
    Replace[
      SelectFirst[$CurrentIssues, 
        StringContainsQ[#Title, pacletName]&&
          StringContainsQ[#Title, "Register"|"registration"]&
        ],
      {
        a_Association?AssociationQ:>
          With[{n=a["Number"]},
            GitHub["CreateIssueComment", 
              $Repository,
              n,
              $pacletUpdateMessage
              ]
            ],
        _:>
          If[retry, 
            LoadIssues[];
            iRequestPacletUpdate[pacletName, False],
            PackageRaiseException[
              Automatic,
              "No paclet registration found for paclet `1`. \
Try PublicPacletServer[\"RegisterPaclet\", \"`1`\"].",
              pacletName
              ]
            ]
        }
      ]
    (*]*)


(* ::Subsubsubsection::Closed:: *)
(*RequestPacletUpdate*)



RequestPacletUpdate[pacletName_String]:=
  iRequestPacletUpdate[pacletName];


(* ::Subsubsection::Closed:: *)
(*Submit*)



(* ::Subsubsubsection::Closed:: *)
(*SubmitPaclet*)



(* ::Text:: *)
(*
	
	Should autodetect whether something is a paclet or not, package it up, then push it into the review queue via a clone and pull request.
	
	Requires GitHub authentication.
*)



PublicPacletServer::badpac=
  "Couldn't generate paclet for ``. \
Check formatting or contact b3m2a1@gmail.com for details.";
PublicPacletServer::noclfk=
  "No clone or fork repositories found. One or the other is required to submit paclets.
Run PublicPacletServer[\"Fork\"] to generate the fork.";


Options[SubmitPaclet]:=
  GitHub["AddFile", "Options"];
SubmitPaclet[paclet_, ops:OptionsPattern[]]:=
  Module[
    {
      pacFile
      },
    If[!StringQ@$Clone&&!StringQ@$Fork, 
      Message[PublicPacletServer::noclfk];
      $Failed,
      pacFile=
        Which[
          StringQ@paclet&&FileExistsQ[paclet]&&FileExtension[paclet]=="paclet",
            paclet,
          MatchQ[paclet, _PacletManager`Paclet?(DirectoryQ[#["Location"]]&)],
            Replace[PacletExecute["Bundle", paclet["Location"]],
              e:Except[_String?FileExistsQ]:>
                (
                  Message[PublicPacletServer::badpac, paclet];
                  $Failed
                  )
              ],
          StringQ@paclet&&Length@PacletManager`PacletFind[paclet]>0,
            With[{pf=PacletManager`PacletFind[paclet][[1]]},
              If[StringQ@pf["Location"]&&DirectoryQ@pf["Location"],
                Replace[PacletExecute["Bundle", pf["Location"]],
                  e:Except[_String?FileExistsQ]:>
                    (
                      Message[PublicPacletServer::badpac, paclet];
                      $Failed
                      )
                  ],
                Message[PublicPacletServer::badpac, paclet];
                $Failed
                ]
              ],
          True,
            Replace[PacletExecute["AutoGeneratePaclet", paclet],
              Except[_String?FileExistsQ]:>
                (
                  Message[PublicPacletServer::badpac, paclet];
                  $Failed
                  )
              ]
          ];
      If[StringQ@pacFile&&FileExistsQ[pacFile]&&FileExtension[pacFile]=="paclet",
        If[StringQ@$Clone,
          CopyFile[
            pacFile,
            FileNameJoin@{$Clone, "ReviewQueue", FileNameTake[pacFile]},
            OverwriteTarget->True
            ];
          Git["Add", $Clone, "All"->True];
          Git["Commit", $Clone, 
            "All"->True, 
            "Message"->"Added paclet "<>FileNameTake[pacFile]<>" to queue"
            ];
          GitHub["Push", $Clone],
          With[
            {
              currentForkQueue=
                PPSGitHubCheck@GitHub["GetDirectory", $Fork, "ReviewQueue"]
              },
            If[ListQ@currentForkQueue,
              Replace[
                PPSGitHubCheck@
                  GitHub[
                    If[MemberQ[Lookup[currentForkQueue, "Name"], FileNameTake[pacFile]],
                      "EditFile",
                      "AddFile"
                      ], 
                    $Fork, 
                    pacFile, 
                    "ReviewQueue/"<>FileNameTake[pacFile],
                    ops,
                    "Message"->
                      If[MemberQ[Lookup[currentForkQueue, "Name"], FileNameTake[pacFile]],
                        "Updated paclet "<>FileNameTake[pacFile]<>" in queue",
                        "Added paclet "<>FileNameTake[pacFile]<>" to queue"
                        ]
                    ],
                a_Association:>
                  URLBuild@
                    <|
                      "Scheme"->"https",
                      "Domain"->"github.com",
                      "Path"->
                        DeleteCases[""]@
                          Flatten@{
                            URLParse[$Fork, "Path"], "tree", "master", 
                            URLParse[a["Content"]["Path"], "Path"]
                            }
                      |>
                ],
              $Failed
              ]
            ]
          ],
        $Failed
        ]
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*SubmitPullRequest*)



(* ::Text:: *)
(*
	Simply set up a PR to the main server
*)



PublicPacletServer::nomrg=
  "Couldn't perform requisite merge request before sending pull request. \
Visit GitHub for more details.";


Options[SubmitPullRequest]:=
  GitHub["CreatePullRequest", "Options"];
SubmitPullRequest[desc:_String|Automatic:Automatic, ops:OptionsPattern[]]:=
  Module[
    {
      merge,
      pull
      },
    merge=
      PPSGitHubCheck@
        GitHub["Merge", $Fork, $Repository];
    pull=
      Replace[
        PPSGitHubCheck@
          GitHub[
            "CreatePullRequest", 
            $Repository,
            ops,
            "Title"->
              "Update Review Queue",
            "Description"->
              "Pull request on review queue changes"
            ],
        {
          a_Association?(AssociationQ):>a["HTMLURL"],
          e_:>If[!AssociationQ@merge, Message[PublicPacletServer::nomrg];$Failed, e]
          }
        ]
    ]


End[];



