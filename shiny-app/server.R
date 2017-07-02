library(shiny)
library(plyr)
library(dplyr)
library(stringr)
require(ggplot2)
# library(shinyFiles)


##partie shiny
shinyServer(function(input, output) {
  
  ##################################################
  ## lecture des donnees
  ##################################################
  
  Dataset <- reactive({
    if (is.null(input$uploadfile)) {
      # l'utilisateur na pas encore charger les donnees
      return(data.frame())
    }else{
        my.data.df <- data.frame()
        for(i in 1:length(input$uploadfile$datapath)){
          if(input$uploadfile$size[i] != 0){
            tmp <- as.data.frame(read.csv(input$uploadfile$datapath[i], 
                                              sep=";", encoding = "Latin1", header = T, stringsAsFactors = F,na.strings=c("","NA")))
            tmp$step <- str_match_all(input$uploadfile$name[i], "[0-9]+") %>% unlist %>% unique %>% as.numeric
            my.data.df <- rbind(my.data.df, tmp)
          }
        }
        return(my.data.df)
    }
  })
  output$tableau <- renderTable({Dataset()})
  
  
  ##################################################
  ## Graphs Actions par Communes
  ##################################################
  
  #graph nombre d'actions par tour
  output$plot_actions <- renderPlot({
      if(length(Dataset()) > 0){
        submerssionT <- as.numeric(unlist(strsplit(input$submerssionT,",")))# on redefinit le type de données issu du vecteur texte
        act.step <- ddply(Dataset(), c("step"), summarise,
                          sum_act   = length(name)
        )
        act.step$sum_true <- c(act.step$sum_act[1], act.step$sum_act[-1] - act.step$sum_act[-nrow(act.step)])
        

        sumbmerssion_color <- "grey"
        gg_action <- ggplot(data =act.step)+
          geom_bar(aes(x = step, y = sum_true), stat = "identity")+
          # geom_line(aes(x = step, y = sum_true))+
          lims(y = c(0,max(act.step$sum_true)))+
          labs(x="Step", y = "Sum actions", title = "Number of actions by step")+
          geom_vline(xintercept=submerssionT[1], colour = sumbmerssion_color)+
          geom_vline(xintercept=submerssionT[2], colour = sumbmerssion_color)+ ## entre tour 5 et 6
          geom_vline(xintercept=submerssionT[3], colour = sumbmerssion_color)+ ## entre tour 8 et 9
          geom_vline(xintercept=submerssionT[4], colour = sumbmerssion_color) ## entre tour 8 et 9
        return(gg_action)

      }else{
        return(NULL)
      }
    })
  
  output$plot_actions_communes <- renderPlot({
    if(length(Dataset()) > 0){
      submerssionT <- as.numeric(unlist(strsplit(input$submerssionT,",")))# on redefinit le type de données issu du vecteur texte
      
      act.step <- ddply(Dataset(), c("commune_name","step"), summarise,
                        sum_act   = length(name)
      )
      
      ## Ici on soustrait les actions du tour d'avant  pour produire un nouveau data frame
      com_name <- unique(act.step$commune_name)
      act.step.resh <- data.frame()
      for(i in com_name){
        sel <- act.step$commune_name == i
        sm <- act.step[sel,]
        sm <- rbind(c("dolus",1,0), sm)
        sm$sum_act <- as.numeric(sm$sum_act)
        sm$step <- as.numeric(sm$step)
        tps.v <- NULL
        for(j in 1:length(sm[,1])){
          if(j == 1){
            tps.v <- c(tps.v, 0)
          }else{
            tps.v <- c(tps.v,sm$sum_act[j] - sm$sum_act[j-1])
          }
        }
        sm$sum_true <- tps.v
        act.step.resh <- rbind(act.step.resh,sm)
      }
      rm(act.step)
      act.step.resh$commune_name <- revalue(act.step.resh$commune_name, c("dolus"="Dolus", "lechateau"="Le Chateau",
                                                                          "stpierre"="St Pierre", "sttrojan"="St Trojan"))
      
      
      
      sumbmerssion_color <- "grey"
      gg_act <- ggplot(data =act.step.resh)+
        geom_bar(aes(x = step, y = sum_true),stat = "identity")+
        # geom_line(aes(x = step, y = sum_true))+
        lims(y = c(0,max(act.step.resh$sum_true)))+
        facet_grid(~commune_name)+
        labs(x="Step", y = "Sum actions", title = "Number of action by commune")+
        geom_vline(xintercept=submerssionT[1], colour = sumbmerssion_color)+
        geom_vline(xintercept=submerssionT[2], colour = sumbmerssion_color)+ ## entre tour 5 et 6
        geom_vline(xintercept=submerssionT[3], colour = sumbmerssion_color)+ ## entre tour 8 et 9
        geom_vline(xintercept=submerssionT[4], colour = sumbmerssion_color) ## entre tour 8 et 9
      return(gg_act)
      
    }else{
      return(NULL)
    }
  })
  
  ##################################################
  ## Graphs profils
  ##################################################
  
  output$plot_profils <- renderPlot({
    if(length(Dataset()) > 0){
      submerssionT <- as.numeric(unlist(strsplit(input$submerssionT,",")))# on redefinit le type de données issu du vecteur texte
      
      
      act.step <- ddply(Dataset(), c("commune_name","step", "tracked_profil"), summarise,
                        sum_act   = length(name)
      )
      act.step$commune_name <- revalue(act.step$commune_name, c("dolus"="Dolus", "lechateau"="Le Chateau",
                                                                "stpierre"="St Pierre", "sttrojan"="St Trojan"))
      act.step$tracked_profil[is.na(act.step$tracked_profil)] <- "Autres"
      
      act.step$tracked_profil <- revalue(act.step$tracked_profil, c("d\\u00E9fense douce"="Défense douce",
                                                                    "retrait"="Retrait", "batisseur"="Batisseur"))
      
      ## Ici on soustrait les actions du tour d'avant  pour produire un nouveau data frame
      com_name <- unique(act.step$commune_name)
      type_name <- unique(act.step$tracked_profil)
      act.step.resh <- data.frame()
      for(i in com_name){
        ## ON selectionne les communes les unes après les autres
        sel <- act.step$commune_name == i
        sm <- act.step[sel,]
        # sm <- rbind(c(i,1,0), sm)
        sm$sum_act <- as.numeric(sm$sum_act)
        sm$step <- as.numeric(sm$step)
        ## On selectionne les type d'actions dans la commune en queston
        for(k in type_name){
          sel <- sm$tracked_profil == k
          sm2 <- sm[sel,]
          if(length(sm2[,1]) > 0){
            sm2 <- na.omit(sm2)
            sm2$sum_true <- c(sm2$sum_act[1], sm2$sum_act[-1] - sm2$sum_act[-nrow(sm2)])
            act.step.resh <- rbind(act.step.resh,sm2)
          }
        }
      }
      rm(act.step)
      
      
      sumbmerssion_color <- "grey"
      gg_act_profil <- ggplot(data =act.step.resh)+
        geom_bar(aes(x = step, y = sum_true, fill = tracked_profil), stat = "identity")+
        # geom_line(aes(x = step, y = sum_true))+
        lims(y = c(0,max(act.step.resh$sum_true)))+
        facet_grid(tracked_profil~commune_name)+
        scale_fill_manual(values = c("#c6c6c6", "#33CCFF", "#31d162","#FF9966"))+
        labs(x="Step", y = "Sum actions", title = "Number of action by commune and profile")+
        geom_vline(xintercept=submerssionT[1], colour = sumbmerssion_color)+
        geom_vline(xintercept=submerssionT[2], colour = sumbmerssion_color)+ ## entre tour 5 et 6
        geom_vline(xintercept=submerssionT[3], colour = sumbmerssion_color)+ ## entre tour 8 et 9
        geom_vline(xintercept=submerssionT[4], colour = sumbmerssion_color) ## entre tour 8 et 9
      return(gg_act_profil)
      
    }else{
      return(NULL)
    }
  })
  
  output$plot_profils_pct <- renderPlot({
    if(length(Dataset()) > 0){
      submerssionT <- as.numeric(unlist(strsplit(input$submerssionT,",")))# on redefinit le type de données issu du vecteur texte
      
      
      ## On a besoin de deux tables
      my.small.tot <- ddply(Dataset(), c("commune_name","step"), summarise,
                            sum_act_tot   = length(name)
      )
      my.small.tot$commune_name <- revalue(my.small.tot$commune_name, c("dolus"="Dolus", "lechateau"="Le Chateau",
                                                                        "stpierre"="St Pierre", "sttrojan"="St Trojan"))
      
      act.step <- ddply(Dataset(), c("commune_name","step", "tracked_profil"), summarise,
                        sum_act   = length(name)
      )
      act.step$commune_name <- revalue(act.step$commune_name, c("dolus"="Dolus", "lechateau"="Le Chateau",
                                                                "stpierre"="St Pierre", "sttrojan"="St Trojan"))
      act.step$tracked_profil[is.na(act.step$tracked_profil)] <- "Autres"
      
      act.step$tracked_profil <- revalue(act.step$tracked_profil, c("d\\u00E9fense douce"="Défense douce",
                                                                    "retrait"="Retrait", "batisseur"="Batisseur"))
      
      ## Ici on soustrait les actions du tour d'avant  pour produire un nouveau data frame
      com_name <- unique(act.step$commune_name)
      type_name <- unique(act.step$tracked_profil)
      act.step.resh <- data.frame()
      for(i in com_name){
        ## ON selectionne les communes les unes après les autres
        sel <- act.step$commune_name == i
        sm <- act.step[sel,] # selection sur la premiere table
        sel <- my.small.tot$commune_name == i
        sm.small <- my.small.tot[sel,] # selecte sur la seconde table
        sm.small$value <- c(sm.small$sum_act[1], sm.small$sum_act[-1] - sm.small$sum_act[-nrow(sm.small)]) # calcule nb actions par tour
        sm <- join(sm, sm.small, by = "step", type = "left")
        # sm <- rbind(c(i,1,0), sm)
        sm$sum_act <- as.numeric(sm$sum_act)
        sm$step <- as.numeric(sm$step)
        ## On selectionne les type d'actions dans la commune en queston
        for(k in type_name){
          sel <- sm$tracked_profil == k
          sm2 <- sm[sel,]
          if(length(sm2[,1]) > 0){
            sm2 <- na.omit(sm2)
            sm2$sum_true <- c(sm2$sum_act[1], sm2$sum_act[-1] - sm2$sum_act[-nrow(sm2)])
            sm2$prop <- sm2$sum_true * 100 / sm2$value
            act.step.resh <- rbind(act.step.resh,sm2)
          }
        }
      }
      act.step.resh <- act.step.resh[,-4]
      
      sumbmerssion_color <- "red"
      gg_profil_pct <- ggplot(data =act.step.resh)+
        geom_bar(aes(x = step, y = prop, fill = tracked_profil), stat = "identity")+
        # geom_line(aes(x = step, y = sum_true))+
        lims(y = c(0,max(act.step.resh$prop)))+
        facet_grid(~commune_name)+
        labs(x="Step", y = "% actions", title = "Number of action by commune and profile")+
        # scale_colour_brewer(name = "profiles", palette = "Set2")+
        scale_fill_manual(values = c("#c6c6c6", "#33CCFF", "#31d162","#FF9966"))+
        geom_vline(xintercept=submerssionT[1], colour = sumbmerssion_color)+
        geom_vline(xintercept=submerssionT[2], colour = sumbmerssion_color)+ ## entre tour 5 et 6
        geom_vline(xintercept=submerssionT[3], colour = sumbmerssion_color)+ ## entre tour 8 et 9
        geom_vline(xintercept=submerssionT[4], colour = sumbmerssion_color) ## entre tour 8 et 9
      gg_profil_pct
      
    }else{
      return(NULL)
    }
  })
  
  ##################################################
  ##  Graph cost by profils
  ##################################################
  
  output$plot_cost_by_communes <- renderPlot({
    if(length(Dataset()) > 0){
      submerssionT <- as.numeric(unlist(strsplit(input$submerssionT,",")))# on redefinit le type de données issu du vecteur texte
      
      act.step <- ddply(Dataset(), c("commune_name","step", "tracked_profil"), summarise,
                        sum_cost   = sum(cost)
      )
      act.step$commune_name <- revalue(act.step$commune_name, c("dolus"="Dolus", "lechateau"="Le Chateau",
                                                                "stpierre"="St Pierre", "sttrojan"="St Trojan"))
      act.step$tracked_profil[is.na(act.step$tracked_profil)] <- "Autres"
      
      act.step$tracked_profil <- revalue(act.step$tracked_profil, c("d\\u00E9fense douce"="Défense douce",
                                                                    "retrait"="Retrait", "batisseur"="Batisseur"))
      
      ## Ici on soustrait les actions du tour d'avant  pour produire un nouveau data frame
      com_name <- unique(act.step$commune_name)
      type_name <- unique(act.step$tracked_profil)
      act.step.resh <- data.frame()
      for(i in com_name){
        ## ON selectionne les communes les unes après les autres
        sel <- act.step$commune_name == i
        sm <- act.step[sel,]
        # sm <- rbind(c(i,1,0), sm)
        sm$sum_cost <- as.numeric(sm$sum_cost)
        sm$step <- as.numeric(sm$step)
        ## On selectionne les type d'actions dans la commune en queston
        for(k in type_name){
          sel <- sm$tracked_profil == k
          sm2 <- sm[sel,]
          if(length(sm2[,1]) > 0){
            sm2 <- na.omit(sm2)
            sm2$sum_true <- c(sm2$sum_cost[1], sm2$sum_cost[-1] - sm2$sum_cost[-nrow(sm2)])
            act.step.resh <- rbind(act.step.resh,sm2)
          }
        }
      }
      rm(act.step)
      
      act.step.tot <- ddply(act.step.resh, c("step", "tracked_profil"), summarise,
                            sum_true   = sum(sum_true)
      )
      
      sumbmerssion_color <- "grey"
      gg_cost_prof_cc <- ggplot(data =act.step.tot)+
        # geom_point(aes(x = step, y = sum_true))+
        geom_bar(aes(x = step, y = sum_true, fill = tracked_profil), stat = "identity")+
        # geom_line(aes(x = step, y = sum_true))+
        lims(y = c(0,max(act.step.resh$sum_true)))+
        facet_grid(tracked_profil~.)+
        labs(x="Step", y = "Cost",title = "Cost by step and profile")+
        scale_fill_manual(values = c("#c6c6c6", "#33CCFF", "#31d162","#FF9966"))+
        labs(x="Step", y = "Cost", title = "Cost by step by commune and profile")+
        geom_vline(xintercept=submerssionT[1], colour = sumbmerssion_color)+
        geom_vline(xintercept=submerssionT[2], colour = sumbmerssion_color)+ ## entre tour 5 et 6
        geom_vline(xintercept=submerssionT[3], colour = sumbmerssion_color)+ ## entre tour 8 et 9
        geom_vline(xintercept=submerssionT[4], colour = sumbmerssion_color) ## entre tour 8 et 9
      gg_cost_prof_cc
      
    }else{
      return(NULL)
    }
  })
  
  output$plot_cost_by_profils <- renderPlot({
    if(length(Dataset()) > 0){
      submerssionT <- as.numeric(unlist(strsplit(input$submerssionT,",")))# on redefinit le type de données issu du vecteur texte
      
      act.step <- ddply(Dataset(), c("commune_name","step", "tracked_profil"), summarise,
                        sum_cost   = sum(cost)
      )
      act.step$commune_name <- revalue(act.step$commune_name, c("dolus"="Dolus", "lechateau"="Le Chateau",
                                                                "stpierre"="St Pierre", "sttrojan"="St Trojan"))
      act.step$tracked_profil[is.na(act.step$tracked_profil)] <- "Autres"
      
      act.step$tracked_profil <- revalue(act.step$tracked_profil, c("d\\u00E9fense douce"="Défense douce",
                                                                    "retrait"="Retrait", "batisseur"="Batisseur"))
      
      ## Ici on soustrait les actions du tour d'avant  pour produire un nouveau data frame
      com_name <- unique(act.step$commune_name)
      type_name <- unique(act.step$tracked_profil)
      act.step.resh <- data.frame()
      for(i in com_name){
        ## ON selectionne les communes les unes après les autres
        sel <- act.step$commune_name == i
        sm <- act.step[sel,]
        # sm <- rbind(c(i,1,0), sm)
        sm$sum_cost <- as.numeric(sm$sum_cost)
        sm$step <- as.numeric(sm$step)
        ## On selectionne les type d'actions dans la commune en queston
        for(k in type_name){
          sel <- sm$tracked_profil == k
          sm2 <- sm[sel,]
          if(length(sm2[,1]) > 0){
            sm2 <- na.omit(sm2)
            sm2$sum_true <- c(sm2$sum_cost[1], sm2$sum_cost[-1] - sm2$sum_cost[-nrow(sm2)])
            act.step.resh <- rbind(act.step.resh,sm2)
          }
        }
      }
      rm(act.step)
      
      sumbmerssion_color <- "grey"
      gg_cost_prof <- ggplot(data =act.step.resh)+
        geom_bar(aes(x = step, y = sum_true, fill = tracked_profil), stat = "identity")+
        # geom_line(aes(x = step, y = sum_true))+
        lims(y = c(0,max(act.step.resh$sum_true)))+
        facet_grid(tracked_profil~commune_name)+
        scale_fill_manual(values = c("#c6c6c6", "#33CCFF", "#31d162","#FF9966"))+
        labs(x="Step", y = "Cost", title = "Cost by step by commune and profile")+
        geom_vline(xintercept=submerssionT[1], colour = sumbmerssion_color)+
        geom_vline(xintercept=submerssionT[2], colour = sumbmerssion_color)+ ## entre tour 5 et 6
        geom_vline(xintercept=submerssionT[3], colour = sumbmerssion_color)+ ## entre tour 8 et 9
        geom_vline(xintercept=submerssionT[4], colour = sumbmerssion_color) ## entre tour 8 et 9
      gg_cost_prof
     
    }else{
      return(NULL)
    }
  })
  
  

})


