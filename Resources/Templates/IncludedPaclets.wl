(* ::Package:: *)

(* ::Section:: *)
(*Included Paclets*)


(* ::Text:: *)
(*Loads the included paclets for the server*)


BeginPackage["PublicPacletServer`"];


BeginPackage["`Build`"]


$IncludedPaclets::usage=
  "The paclets built into the server that weren't manually commited";


EndPackage[]


Begin["`Private`"]


$IncludedPaclets=
  <|
    
    |>;


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
