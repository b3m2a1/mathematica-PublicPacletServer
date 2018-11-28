(* ::Package:: *)

(* Autogenerated Package *)

(* ::Section:: *)
(*PublicPacletServer*)



BeginPackage["`Package`"];


SubmitPublicPaclet::usage=
  "Submits a paclet to the public paclet server for review";


CloneReviewQueue::usage=
  "Clones the review queue for to allow for easier manual submissions";


PublicPacletInstall::usage=
  "Installs a paclet from the public paclet server";


EndPackage[];


Begin["`Private`"];


(* ::Subsubsection::Closed:: *)
(*Set Up*)



(* ::Subsubsubsection::Closed:: *)
(*Constants*)



$PublicPacletServerURL=
  "https://raw.githubusercontent.com/paclets/PacletServer/master";


(* ::Subsubsubsection::Closed:: *)
(*Dependencies*)



PackageLoadPacletDependency["BTools`"]


<<BTools`Paclets`
<<BTools`External`


(* ::Subsubsubsection::Closed:: *)
(*Basic Messages*)



PublicPacletServer::noauth=
  "Public paclet server requires authentication with GitHub";


(* ::Subsubsection::Closed:: *)
(*Fork*)



(* ::Subsubsubsection::Closed:: *)
(*ForkedQ*)



PacletServerForkedQ[]:=
  With[{ghdat=GitHub["ListMyRepositories", "ImportedResult"]},
    If[!AssociationQ@ghdat, 
      Message[PublicPacletServer::noauth];
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*Fork*)



(* ::Subsubsection::Closed:: *)
(*SubmitPublicPaclet*)



(* ::Text:: *)
(*
	
	Should autodetect whether something is a paclet or not, package it up, then push it into the review queue via a clone and pull request.
	
	Requires GitHub authentication.
*)



Options[SubmitPublicPaclet]=
  {
    "Username"->Automatic,
    "Password"->Automatic
    };
SubmitPublicPaclet[paclet_, ops:OptionsPattern[]]:=
  Replace[PacletExecute["AutoGeneratePaclet", paclet],
    f_String?FileExistsQ:>
      GitHub["Clone"]
    ]


(* ::Subsubsection::Closed:: *)
(*PublicPacletInstall*)



(* ::Subsubsubsection::Closed:: *)
(*downloadRawPacletsToo*)



Options[downloadRawPacletsToo] = 
  {"CompletionFunction" -> None};
downloadRawPacletsToo[
  remotePaclet_PacletManager`Paclet,
  async:(True|False):True,
  OptionsPattern[]
  ]:=
  Module[
    {
      loc,downloadTask,pacletFileName,downloadedFileName,
      truePaclet, pName
      },
    loc=PacletManager`Package`PgetLocation[remotePaclet];
    pName=PacletManager`Package`PgetQualifiedName[remotePaclet];
    pacletFileName=pName<>".paclet";
    truePaclet=
      Which[
        StringEndsQ[loc, pacletFileName],
        loc,
      (* should add some GitHub logic... *)
      True,
        loc<>"/Paclets/"<>ExternalService`EncodeString[pacletFileName]
      ];
    (*To avoid conflicts with multiple instances of M,or preemptive computations,
		downloading the same paclet,generate a unique name for the download file.*)
    downloadedFileName=
      ToFileName[
        PacletManager`Package`$userTemporaryDir,
        pName<>ToString[$ProcessID]<>
          ToString[Random[Integer,{1, 1000}]]<>".paclet"
        ];
    If[StringMatchQ[loc,"http*:*",IgnoreCase->True]||
      StringMatchQ[loc,"file:*",IgnoreCase->True],
      If[async,
        PreemptProtect[(*Use PreemptProtect to ensure that setTaskData[] 
					gets called before pacletDownloadCallback can fire.*)
          downloadTask=
        URLSaveAsynchronous[
            truePaclet,
            downloadedFileName,
            PacletManager`Manager`Private`pacletDownloadCallback,
            "Headers"->
              {
                "Mathematica-systemID"->$SystemID,
                "Mathematica-license"->ToString[$LicenseID],
                "Mathematica-mathID"->ToString[$MachineID],
                "Mathematica-language"->ToString[$Language],
                "Mathematica-activationKey"->ToString[$ActivationKey]
                },
            "UserAgent"->PacletManager`Package`$userAgent,
            BinaryFormat->True,
            "Progress"->True
            ];
          PacletManager`Package`setTaskData[downloadTask,
            {
              pName,
              downloadedFileName,
              loc,
              "Running",
              OptionValue["CompletionFunction"],
              0,
              "",
              "Unknown"
              }]];
          downloadTask,(*else*)
          (*Synchronous; returns filename.*)
          URLSave[truePaclet,
            ToFileName[PacletManager`Package`$userTemporaryDir, pacletFileName],
            "UserAgent"->PacletManager`Package`$userAgent,
            BinaryFormat->True
            ]
          ],
        (*else*)
        $Failed
        ]
      ]


(* ::Subsubsubsection::Closed:: *)
(*setNonRemoteLocation*)



setNonRemoteLocation[paclets:_Paclet,location_String]:=
  setNonRemoteLocation[{paclets},location][[1]];
setNonRemoteLocation[paclets:{___PacletManager`Paclet}, location_String]:=
  Module[
    {
      loc,
      fullLoc,
      remStackLen=
        Length[Stack[_PacletManager`PacletFindRemote]],
      inRem
      },
    inRem=remStackLen>0;
    fullLoc=
      If[StringMatchQ[location,"http*:*", IgnoreCase->True]||
        StringMatchQ[location,"file:*", IgnoreCase->True],
        location,
        ExpandFileName[location]
        ];
    Function[
      loc=PacletManager`Package`getPIValue[#, "Location"];
      If[loc===Null,
        Append[#, "Location"->fullLoc],
        If[inRem, #, #/.("Location"->_):>("Location"->fullLoc)]
        ]
      ]/@paclets
    ];


(* ::Subsubsubsection::Closed:: *)
(*PublicPacletInstall*)



PublicPacletInstall[name_, ops:OptionsPattern[]]:=
  Block[
    {
      PacletManager`Package`setLocation=setNonRemoteLocation,
      PacletManager`Package`downloadPaclet=downloadRawPacletsToo
      },
    PacletManager`PacletInstall[
      name,
      ops,
      "Site"->"http://paclets.github.io/PacletServer"
      ]
    ]


End[];



