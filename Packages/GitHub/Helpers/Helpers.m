(* ::Package:: *)



PPSGitHubCheck::usage=
  "Checks the results coming out of GitHub";


Begin["`Private`"];


(* ::Subsubsection::Closed:: *)
(*Common Messages*)



PublicPacletServer::noauth=
  "Public paclet server requires authentication with GitHub";
PublicPacletServer::nohub=
  "Public paclet server can't connect to github.com. \
Are you connected to the internet?";
PublicPacletServer::badreq=
  "Request to GitHub failed with message: \"``\"
Contact b3m2a1@gmail.com for details.";
PublicPacletServer::badcon=
  "Request couldn't be completed due to a conflict with message: \"``\"
Contact b3m2a1@gmail.com for details.";
PublicPacletServer::badend=
  "Request couldn't be completed due to missing endpoint with message: \"``\"
Contact b3m2a1@gmail.com for details.";
PublicPacletServer::badhub=
  "Internal error, request to GitHub failed.
Contact b3m2a1@gmail.com for details.";


(* ::Subsubsection::Closed:: *)
(*PPSGitHubCheck*)



PPSGitHubCheck[resObj_]:=
  With[{res=If[MatchQ[resObj, _Failure], Last@resObj, resObj]},
    Which[
      Head[res]===GitHub,
        Message[PublicPacletServer::badhub];
        $Failed,
      MatchQ[res, _Success],
        res,
      MatchQ[res, _Failure],
      res["StatusCode"]===401,
        Message[PublicPacletServer::noauth];
        $Failed,
      res["StatusCode"]===404,
        Message[PublicPacletServer::badend, res["Message"]];
        $Failed,
      res["StatusCode"]===409,
        Message[PublicPacletServer::badcon, res["Message"]];
        $Failed,
      res["StatusCode"]>400,
        Message[PublicPacletServer::badreq, StringReplace[res["Message"], "\n"->" "]];
        $Failed,
      !AssociationQ@res,
        res;
        Message[PublicPacletServer::nohub];
        $Failed,
      True,
        res["Content"]
      ]
    ]
      


End[];



