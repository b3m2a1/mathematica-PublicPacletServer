(* ::Package:: *)

(* ::Section:: *)
(*Included Paclets*)


(* ::Text:: *)
(*Loads the included paclets for the server*)


(* ::Subsubsection::Closed:: *)
(*Setup*)


BeginPackage["PublicPacletServer`"];


BeginPackage["`Build`"]


$IncludedPaclets::usage=
  "The paclets built into the server that weren't manually commited";


EndPackage[]


Begin["`Private`"]


$IncludedPaclets=
  <|
    
    |>;


(* ::Subsection:: *)
(*Edit*)


(* ::Text:: *)
(*A sample registration would like*)


(* ::Input:: *)
(*$IncludedPaclets["PacletName"]=*)
(*  <|*)
(*		"Name" -> "PacletName",*)
(*		"Author" -> "Author Name <author@e.mail>",*)
(*		"Site" -> "https://paclet.site",*)
(*		"Update" -> <UpdateSpec>*)
(*	|>*)


(* ::Text:: *)
(*The possible UpdateSpecs are DownloadAlways, DownloadOnce, and DownloadNever*)


<*Insert Paclets*>


(* ::Subsubsection::Closed:: *)
(*End*)


End[]


(* ::Subsection:: *)
(*EndPackage*)


EndPackage[]


(* ::Subsection:: *)
(*Expose*)


Values@PublicPacletServer`Build`$IncludedPaclets
