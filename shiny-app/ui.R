library(shiny)
#library(shinyFiles)

shinyUI(navbarPage(
  title=div(img(src="logo_littoSim.png", height = 50, width = 50)),
  "Site compagnon LittoSim",
  tabPanel("Télécharger",
  sidebarLayout(
    sidebarPanel(
      p("Traitement des résultats du jeux ",a("LittoSim", href ="https://littosim.github.io/LittoSim_model/"),", 
        un jeux serieux sur la submerssion marine."),
      img(src = "logo_littoSim.png",height = 90, width = 90, style="display: block; margin-left: auto; margin-right: auto;"),
      tags$hr(),
      #shinyDirButton("dir", "Chose directory", "Upload"),
      fileInput('uploadfile', 'Actions done', multiple=TRUE, accept = c(".csv")),
      textInput('submerssionT', 'Submerssion times', "0.5,4.5,9.5,12.5"),
      tags$hr(),
      p("Un jeu et une application développé par :"),
      img(src = "logo_cnrs.png",height = 60, style="display: inline-block;vertical-align:top; margin-left: auto;"),
      img(src = "logo-ird.png",height = 60, style="display: inline-block;vertical-align:top;margin-right: auto;")
    ),
    mainPanel(
      tableOutput('tableau')
    )
    # mainPanel(
    #   h4("Files in that directory"),
    #   verbatimTextOutput("files")
    # )
  )
),
tabPanel("Graphs Actions",
         mainPanel(
          h3("Nombre d'actions par commune et par tour"),
          plotOutput(outputId = "plot_actions", height = "500px"),
          h3("Nombre d'actions par tour et par commune"),
          plotOutput(outputId = "plot_actions_communes", height = "500px")
          
         )
),
tabPanel("Graphs profils",
         mainPanel(
           h3("Nombre d'actions par tour"),
           plotOutput(outputId = "plot_profils", height = "700px", width = "900px"),
           h3("Nombre d'actions par tour en %"),
           plotOutput(outputId = "plot_profils_pct", height = "700px", width = "900px")

         )
),
tabPanel("Graphs coûts",
         mainPanel(
           h3("Evolution de l'indice de Gini durant la partie"),
           plotOutput(outputId = "plot_cost_by_communes", height = "500px", width = "900px"),
           h3("Nombre d'actions par tour"),
           plotOutput(outputId = "plot_cost_by_profils", height = "500px", width = "900px")
         )
)
# tabPanel("Aide",
#     withMathJax(),
#     helpText(tags$h1("Le rapport d'incidence standardisé : Le SIR"),
#              tags$h3("Définition"),
#              div("Le SIR (standardized incidence ratio) ou standardisation indirecte repose sur la comparaison du nombre total des cas observé dans la population étudiée par rapport au nombre de cas auquel on pourrait s’attendre si cette population était soumise à une force d'incidence donnée (taux de référence).")),
#     helpText("$$ SIR=\\frac{Observé}{Attendus}$$"),
#     helpText("le SIR est une mesure du risque relatif de la population étudiée par rapport à une population de référence."),
#     helpText(tags$h3("Variabilité des SIR et intervalle confiance"),
#              "La variabilité des SIR ne dépend pratiquement que du numérateur O, le dénominateur étant considéré comme non aléatoire,
#   Les \\(O_{i}\\) suivent une distribution de poisson d'espérance \\(\\theta_{i}\\)\\(E_{i}\\)
#  ou \\(\\theta_{i}\\) correspond au vrai risque relatif de la région \\(i\\)
#   dont le SIR est une estimation."),
#     
#     helpText("$$O_{i}\\sim{}P(\\theta_{i}E_{i})$$"),
#     helpText("On met a profit la relation existant entre la loi de Poisson et la loi du Khi2\\(^{1,2}\\) pour calculer l'interval de confiance
#              d'un paramètre d'une loi de Poisson à un niveau alpha donné."),
#     helpText("$$IC\\left[\\frac{\\chi^2_{\\frac{\\alpha}{2};2.O}}{2E};\\frac{\\chi^2_{1-\\frac{\\alpha}{2};2(O+1) }} {2E}\\right]$$"),
#     
#     
#     ##bibliographie
#     helpText("1- Calculating Poisson confidence Intervals in Excel.",br(),
# "Iain Buchan January 2004",br(),
# "Public Health Informatics at the University of Manchester (www.phi.man.ac.uk)"),
#     helpText("2- Intervalle de confiance pour le paramètre d’une loi de Poisson
# Méthode exacte pour échantillons de taille quelconque.")
#              )
)

)

