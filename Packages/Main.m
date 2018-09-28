(* ::Package:: *)



PublicPacletServer::usage=
  "Represents the public paclet server at https://github.com/paclets/PacletServer";


Begin["`Private`"];


Unprotect[PublicPacletServer];
Clear[PublicPacletServer];


(* ::Subsection:: *)
(*Load BTools*)



PackageLoadPacletDependency["BTools`"]


PackageExtendContextPath[
  {
    "BTools`",
    "BTools`External`",
    "BTools`Paclets`"
    }
  ]


(* ::Subsection:: *)
(*Interface*)



(* ::Subsubsection::Closed:: *)
(*Command List*)



$ServerCommands=
  {
    "RegisterPaclet",
    "RequestPacletUpdate",
    "Repository",
    "RepositoryShort",
    "SiteURL",
    "Fork",
    "ForkedQ",
    "SubmitPacletToFork",
    "SubmitPullRequest",
    "Clone",
    "FindClone",
    "RebuildServer",
    "QueuedPaclets",
    "QueuedPullRequests"
    }


(* ::Subsubsection::Closed:: *)
(*Constants*)



(* ::Subsubsubsection::Closed:: *)
(*Repository*)



PublicPacletServer["Repository"]:=
  URL@$Repository;


(* ::Subsubsubsection::Closed:: *)
(*RepositoryShort*)



PublicPacletServer["RepositoryShort"]:=
  URLBuild@Normal@$Repository;


(* ::Subsubsubsection::Closed:: *)
(*URL*)



PublicPacletServer["SiteURL"]:=
  $URL;


(* ::Subsubsection::Closed:: *)
(*Register*)



(* ::Subsubsubsection::Closed:: *)
(*Register*)



PublicPacletServer["RegisterPaclet", p_]:=
  With[{res=RegisterPaclet[p]},
    res/;Head[res]=!=RegisterPaclet
    ]


(* ::Subsubsubsection::Closed:: *)
(*RequestPacletUpdate*)



PublicPacletServer["RequestPacletUpdate", p_]:=
  With[{res=RequestPacletUpdate[p]},
    res/;Head[res]=!=RequestPacletUpdate
    ]


(* ::Subsubsection::Closed:: *)
(*Fork*)



(* ::Subsubsubsection::Closed:: *)
(*ForkedQ*)



PublicPacletServer["ForkedQ"]:=
  ForkedQ[];


(* ::Subsubsubsection::Closed:: *)
(*Fork*)



PublicPacletServer["Fork"]:=
  Fork[]


(* ::Subsubsection::Closed:: *)
(*Clone*)



(* ::Subsubsubsection::Closed:: *)
(*Clone*)



PublicPacletServer["Clone"]:=
  Clone[]


(* ::Subsubsubsection::Closed:: *)
(*FindClone*)



PublicPacletServer["FindClone"]:=
  FindClone[]


(* ::Subsubsection::Closed:: *)
(*Submit*)



(* ::Subsubsubsection::Closed:: *)
(*SubmitPaclet*)



PublicPacletServer["SubmitPaclet", pacSpec_, ops:OptionsPattern[]]:=
  With[{res=SubmitPaclet[pacSpec, ops]},
    res/;Head[res]=!=SubmitPaclet
    ]


(* ::Subsubsubsection::Closed:: *)
(*SubmitPullRequest*)



PublicPacletServer["SubmitPullRequest", 
  desc:_String|Automatic:Automatic, ops:OptionsPattern[]]:=
  With[{res=SubmitPullRequest[desc, ops]},
    res/;Head[res]=!=SubmitPullRequest
    ]


(* ::Subsubsection::Closed:: *)
(*Queue*)



(* ::Subsubsubsection::Closed:: *)
(*QueuedPaclets*)



PublicPacletServer["QueuedPaclets", which:_String|Automatic:Automatic]:=
  QueuedPaclets[which];


(* ::Subsubsubsection::Closed:: *)
(*QueuedPullRequests*)



PublicPacletServer["QueuedPullRequests", which:_String|Automatic:Automatic]:=
  QueuedPullRequests[which];


(* ::Subsubsection::Closed:: *)
(*Build*)



(* ::Subsubsubsection::Closed:: *)
(*Rebuild*)



PublicPacletServer["Rebuild", arg:_String|{__String}, ops:OptionsPattern[]]:=
  With[{res=RebuildServer[arg, ops]},
    Null/;Head[res]=!=RebuildServer
    ]


(* ::Subsubsubsection::Closed:: *)
(*DownloadPaclets*)



PublicPacletServer["UpdateQueue", ops:OptionsPattern[]]:=
  With[{res=RebuildServer[{"UpdateQueue"}, ops]},
    Null/;Head[res]=!=RebuildServer
    ]


(* ::Subsubsubsection::Closed:: *)
(*BuildPages*)



PublicPacletServer["BuildLog", ops:OptionsPattern[]]:=
  With[{res=RebuildServer[{"Log"}, ops]},
    Null/;Head[res]=!=RebuildServer
    ]


(* ::Subsubsubsection::Closed:: *)
(*AddPaclets*)



PublicPacletServer["AddPaclets", ops:OptionsPattern[]]:=
  With[{res=RebuildServer[{"Add"}, ops]},
    Null/;Head[res]=!=RebuildServer
    ]


(* ::Subsubsubsection::Closed:: *)
(*BuildPages*)



PublicPacletServer["BuildPages", ops:OptionsPattern[]]:=
  With[{res=RebuildServer[{"Build"}, ops]},
    Null/;Head[res]=!=RebuildServer
    ]


(* ::Subsubsubsection::Closed:: *)
(*TestServer*)



PublicPacletServer["TestServer", ops:OptionsPattern[]]:=
  With[{res=RebuildServer[{"Test"}, ops]},
    Null/;Head[res]=!=RebuildServer
    ]


(* ::Subsubsubsection::Closed:: *)
(*PushServer*)



PublicPacletServer["PushServer", ops:OptionsPattern[]]:=
  With[{res=RebuildServer[{"Push"}, ops]},
    Null/;Head[res]=!=RebuildServer
    ]


(* ::Subsection:: *)
(*Clean Up*)



PublicPacletServer["AddAutocompletions"]:=
  PackageAddAutocompletions[
    PublicPacletServer,
    {
      $ServerCommands
      }
    ]


(* ::Subsubsection::Closed:: *)
(*Autocomplete*)



PackageAddAutocompletions[
  PublicPacletServer,
  {
    $ServerCommands
    }
  ]


(* ::Subsubsection::Closed:: *)
(*Protections*)



Protect[PublicPacletServer];


End[];



