library(ggplot2)

#Introduction to ggplot() function
ggplot()

ggplot(data = df, mapping = aes(x = age))+
  geom_histogram()


#Practice
ggplot (data = df, 
        mapping = aes (x = age, y = sbp))+  
  geom_point(shape = "square",color="blue",size = 1)


# Adding aesthetic
ggplot (data = df, 
        mapping = aes (x = age))+  
  geom_histogram(binwidth=7,fill= "pink",color = "black")

#add more bins to histogram
ggplot(df, aes(x = age))+ 
  geom_histogram(bins = 50,fill= "pink",color = "black")


#Scaled to column
ggplot (data = df, 
        mapping = aes (x = age, 
                       y = sbp,color = age))+  
  geom_point()


#Stacked histogram
ggplot(data = df, mapping = aes(x = age, fill = sex)) +
  geom_histogram(binwidth = 2)


## alternative
ggplot (data = df, 
        mapping = aes (x = age, y = sbp))+  
  geom_point(mapping = aes(color=age))

#Group
ggplot (data = df, 
        mapping = aes (x = age, 
                       y = sbp, color = sex))+  
  geom_point()

#facet wrap
ggplot (data = df, 
        mapping = aes (x = age, 
                       y = sbp,color = sex))+  
  geom_point() + facet_wrap(~wealth_index)

#facet grid
ggplot (data = df, 
        mapping = aes (x = age, 
                       y = sbp))+  
  geom_point(color="blue") + facet_grid(sex~wealth_index)

#add labels to the dataset
ggplot (data = df,         
        mapping = aes (x = age, y = sbp, color = sex))+    
  geom_point() +
  labs( title = "Fig1: Age and SBP distribution",    
        subtitle = "Survey data,India - 2021",   
        x = "Age in years",    
        y = "SBP in mmHg")

#assumption as plot1
plot1<-ggplot (data = df,         
               mapping = aes (x = age, y = sbp, color = sex))+    
  geom_point() +
  labs( title = "Fig1: Age and SBP distribution",    
        subtitle = "Survey data,India - 2021",   
        x = "Age in years",    
        y = "SBP in mmHg")


#add theme
plot1+ theme_classic()
plot1+ theme_minimal()
plot1+theme_bw()

#modify themes
plot1 +    
  theme_classic()+    
  theme( legend = "bottom",                     
         plot.title = element_text(size = 10),        
         plot.subtitle = element_text(face = "italic"),     
         axis.text.x = element_text(color = "red", size = 8, angle = 90),  axis.text.y = element_text(size = 8),                  
         axis.title = element_text(size = 5)) 

#Box plot
ggplot(data = df, mapping = aes(y = glucose, x = sex, fill = bpl)) + 
  geom_boxplot()

ggplot(data = df, mapping = aes(y = glucose, x = sex,color = bpl)) + 
  geom_boxplot()

# jitter plot
ggplot(data = df, mapping = aes(x = HTN,y=age, color = HTN)) + 
  geom_jitter()

# jitter plot
ggplot(data = df, mapping = aes(x = HTN,y=age, fill = HTN)) + 
  geom_violin()

#sina plot
install.packages(ggforce)
library(ggforce)
ggplot(data = df, mapping = aes(x = HTN,y=age, color = HTN)) + 
  geom_violin() + geom_sina(aes(color = HTN))

#geom bar
ggplot(data=df, mapping = aes(x=wealth_index,fill=sex)) + 
  geom_bar(width = 0.7)

#geom-line
ggplot(data=df, aes(x=age, y=sbp)) +
  geom_line()

#geom_smooth
ggplot(data=df, aes(x=age, y=sbp)) +
  geom_smooth()


#cord flip
ggplot(data=df, mapping = aes(x=wealth_index,fill=sex)) + 
  geom_bar(width = 0.7)+ coord_flip()


#reorder
ggplot(data=df, mapping = aes(x=wealth_index,fill=sex)) + 
  geom_bar(width = 0.7)+ coord_flip()

#x lim
ggplot(data=df, mapping = aes(x=wealth_index,fill=sex)) + 
  geom_bar(width = 0.7)+ coord_flip()+ ylim(0,200)

#set x and y axis
plot1 + coord_cartesian(xlim =c(18,90), ylim = c(50,200))
