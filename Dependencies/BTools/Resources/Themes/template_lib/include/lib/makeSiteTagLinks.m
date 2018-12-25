With[{args=#2,tags=StringTrim@If[StringQ[#],StringSplit[#,","],#]},
  If[Length[tags]>0,
    $$templateLib["makeSiteHyperlink"][
      Append[
        <|
          "href"->
            URLBuild@{
              "tags",
              #<>".html"
              },
          "body"->#<>", "
          |>&/@Most@tags,
        <|
          "href"->
            URLBuild@{
              "tags",
              #<>".html"
              },
          "body"->#
          |>&@Last[tags]
        ],
      #2
      ],
    ""
    ]
  ]&
