Paclet[
  Name -> "PublicPacletServer",
  Version -> "0.0.10",
  Description -> "A toolchain for working with the public paclet server",
  Thumbnail -> "PacletIcon.png",
  Extensions -> {
    	{
     		"Kernel",
     		"Root" -> ".",
     		"Context" -> {"PublicPacletServer`"}
     	},
    	{
     		"PacletServer",
     		"Description" -> 
      "A beta version of a paclet for interfacing with the public paclet server
Current supports:
  forking the server, submitting paclets, sending PRs,
  cloning the server, and building the server"
     	},
    	{
     		"Resource",
     		"Root" -> "Resources",
     		"Resources" -> {
       			"Templates",
       			{
        				"ExtraPacletInfo",
        				"Templates/ExtraPacletInfo.wl"
        			},
       			{
        				"IncludedPaclets",
        				"Templates/IncludedPaclets.wl"
        			}
       		}
     	}
    }
 ]