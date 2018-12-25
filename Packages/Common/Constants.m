(* ::Package:: *)

(* Autogenerated Package *)

$Repository::usage=
  "The GitHubPath to the server repo";
$URL::usage=
  "The URL for installing things from the repository";
$Paclets::usage=
  "The local clone of the paclets repository";
$Clone::usage=
  "The local clone of the server";
$Fork::usage=
  "The current user's fork of the server";


$Birthday::usage=
  "The paclet server creation date";


$AnalyticsID::usage=
  "The ID for Google Analytics";


Begin["`Private`"];


PublicPacletServer; (* invoke the autoloader *)


(* ::Subsubsubsection::Closed:: *)
(*Repository*)



$Repository:=
  $Repository=
    GitHub["Path", "paclets/PacletServer"];


(* ::Subsubsubsection::Closed:: *)
(*URL*)



$URL=
  "https://raw.githubusercontent.com/paclets/PacletServer/master";


(* ::Subsubsubsection::Closed:: *)
(*Clone*)



$Clone:=
  $Clone=FindClone[]


(* ::Subsubsubsection::Closed:: *)
(*$Paclets*)



$Paclets:=
  $Paclets=FindPacletsClone[];


(* ::Subsubsubsection::Closed:: *)
(*$Fork*)



$Fork:=
  FirstCase[
    Lookup[$CurrentForks, "FullName"],
    Alternatives@@Lookup[$CurrentRepos, "FullName"], 
    None
    ]


(* ::Subsubsubsection::Closed:: *)
(*$Birthday*)



$Birthday=DateObject[{2018, 4, 29}];


(* ::Subsubsubsection::Closed:: *)
(*$AnalyticsID*)



$AnalyticsID=174406285;


End[];



