(* ::Subsection::Closed:: *)
(*Temp Loading Flag Code*)


Temp`PackageScope`PublicPacletServerLoading`Private`$PackageLoadData=
  If[#===None, <||>, Replace[Quiet@Get@#, Except[_?OptionQ]-><||>]]&@
    Append[
      FileNames[
        "LoadInfo."~~"m"|"wl",
        FileNameJoin@{DirectoryName@$InputFileName, "Config"}
        ],
      None
      ][[1]];
Temp`PackageScope`PublicPacletServerLoading`Private`$PackageLoadMode=
  Lookup[Temp`PackageScope`PublicPacletServerLoading`Private`$PackageLoadData, "Mode", "Primary"];
Temp`PackageScope`PublicPacletServerLoading`Private`$DependencyLoad=
  TrueQ[Temp`PackageScope`PublicPacletServerLoading`Private`$PackageLoadMode==="Dependency"];


(* ::Subsection:: *)
(*Main*)


If[Temp`PackageScope`PublicPacletServerLoading`Private`$DependencyLoad,
  If[!TrueQ[Evaluate[Symbol["`PublicPacletServer`PackageScope`Private`$LoadCompleted"]]],
    Get@FileNameJoin@{DirectoryName@$InputFileName, "PublicPacletServerLoader.wl"}
    ],
  If[!TrueQ[Evaluate[Symbol["PublicPacletServer`PackageScope`Private`$LoadCompleted"]]],
    <<PublicPacletServer`PublicPacletServerLoader`,
   BeginPackage["PublicPacletServer`"];
   EndPackage[];
   ]
  ]