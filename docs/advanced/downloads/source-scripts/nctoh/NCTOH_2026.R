## Basics of Data Visualisation in R #### Session by Dr Rudresh Negi

####type in your directory path in setwd() or 
#use the Session-->Set Working Directory menu options


setwd("D:/R studio/workshop/nctoh")


####Importing Data in R

####Import CSV

# ggplot 
library(ggplot2)
library(dplyr)
#Introduction to ggplot() function
ggplot()

## Histogram ####

ggplot(data = overall_age_u, mapping = aes(x = current_age))+
  geom_histogram()

##  A histogram with density scale can be plotted with computed variable ..density.. as:
ggplot(data = overall_age_u, mapping = aes(x = current_age))+
  geom_histogram(aes(y = after_stat(density))) # y = ..density.. is equivalent to y = after_stat(density) function and plots density



# Adding aesthetic
ggplot (data = overall_age_u, 
        mapping = aes (x = current_age))+  
  geom_histogram(binwidth=7, fill= "pink",color = "black") # # binwidth how wide are the columns

#add more bins to histogram
ggplot(overall_age_u, aes(x = current_age))+ 
  geom_histogram(bins = 50,fill= "pink",color = "black") # bins is number of columns


#deciding number of bins - Sturges' rule
# k = 1 + log2(n) ; k is number of bin, n is sample size

# binwidth = range i.e (maximum - minimum )/k

1 + log2(length(overall_age_u$current_age))

ggplot(overall_age_u, aes(x = current_age))+ 
  geom_histogram(bins = 11,fill= "pink",color = "black")

# Adding a vertical line for mean
ggplot(data = overall_age_u, mapping = aes(x = current_age)) + 
  geom_histogram(binwidth = 2,fill= "pink",color = "black") + 
  geom_vline(aes(xintercept = mean(current_age)), 
             linewidth = 0.5, linetype = "dashed", alpha = 0.8, color = "black")

#Stacked histogram
ggplot(data = overall_age_u, mapping = aes(x = current_age, fill = factor(intervention))) +
  geom_histogram(binwidth = 2) 

overall_age_u |> 
  mutate(intervention = factor(intervention, labels = c("control", "intervention"))) |> 
  ggplot(aes(x=current_age,
             fill= intervention))+
  geom_histogram(bins=30, , color = "black")

?geom_histogram

#factorisation of categorical variables
overall_up <- overall_age_u |> 
  mutate(
    intervention = factor(intervention, labels = c("control", "intervention")),
    fuel_type = factor(fuel_type, labels = c("clean", "solid"))
  )

# Adding labels

overall_up |> 
ggplot(mapping = aes(x = current_age, fill = intervention, color = intervention)) + 
  geom_histogram(bins = 11, position = "stack") + # A position adjustment to use on the data for this layer. other positions are dodge, fill, identity,jitter
  geom_vline(aes(xintercept = mean(current_age)), 
             linewidth = 0.5, linetype = "dashed", alpha = 0.8, color = "black") +
  labs(title = "Age distribution", 
       subtitle = "2025", 
       x = "Age", 
       y = "Frequency", 
       fill = "Intervention")
# + guides(color = "none")

#creating categories in continuous data and visualizing them in histogram

overall_up |> mutate(
  age_cat = cut(
    current_age,
    breaks = c(-Inf, 18, 34, 49, 65, Inf),
    labels = c(
      "<19",
      "19–34",
      "35–49",
      "50–65",
      ">65"),right = TRUE)
  ) |> 
  ggplot(mapping = aes(x = current_age, fill = age_cat)) + 
  geom_histogram(bins = 11, color = "black") + # A position adjustment to use on the data for this layer. other positions are dodge, fill, identity,jitter
  geom_vline(aes(xintercept = mean(current_age)), 
             linewidth = 0.5, linetype = "dashed", alpha = 0.8, color = "black") +
  labs(title = "Age distribution", subtitle = "2025", x = "Age", y = "Frequency")


## density plot ####
overall_up |> 
ggplot()+
  geom_density(aes(x=age_of_onset,
                   fill=intervention),
               alpha=.3, 
               color= "black")            

# Adding density plot to histogram

overall_up |> 
  filter(!is.na(age_of_onset)) |> 
ggplot(mapping = aes(x = age_of_onset)) + 
  geom_histogram(aes(y = after_stat(density)), bins = 50, fill = "pink", color = "black") + 
  geom_density(color = "red", linewidth = 1)


## bar plot ####
overall_up |> 
  ggplot(mapping = aes(x= fuel_type))+
  geom_bar() # geom_bar for discrete data


# Adding themes and modifying some theme elements
overall_up |> 
  ggplot(mapping = aes ( x = fuel_type))+
  geom_bar(fill = "Maroon", color = "black")+
  geom_text(stat = "count", aes(label = ..count..), vjust = -.5, hjust = 0)+
  labs(title = "Gender distribution", subtitle = "2025", x = "Frequency", y = "Gender")+
  theme_minimal(base_family = "serif")+    # # also show with other themes eg theme_minimal(), theme_bw()
  theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"), # hjust=0.5 gives centre alignment
        plot.subtitle = element_text(face = "italic"),
        axis.title = element_text(size = 12),
        axis.text.x = element_text(color = "Blue", size = 10, angle = 90),                   
        axis.text.y = element_text(size = 10, angle = 45) # to change angle of labels by 45 degree   
  )


?geom_text
# stat="count" tells geom_text to compute counts like geom_bar() does.
# aes(label = ..count..) uses the computed count as the label.
# vjust = -0.5 places the label slightly above the bar.
# hjust = 0 aligns the start of the text at the x position (right side of label is at the given x

overall_up |> 
  ggplot(mapping = aes ( x = fuel_type))+
  geom_bar(fill = "maroon", color = "black")+
  geom_text(stat = "count", aes(label = ..count..), vjust = -.5, hjust = 0) + 
  coord_flip()

library(dplyr)
library(forcats)

# Decreasing bar
overall_up |> 
  mutate(fagerstrom_baseline = fct_rev(fct_infreq(fagerstrom_catft_0))) |>  # to arrange as per decreasing frequency; for inc. freq remove func fct_rev
  filter(!is.na(fagerstrom_baseline)) |> 
  ggplot(mapping = aes ( y =  fagerstrom_baseline))+
  geom_bar(fill = "maroon", color = "black")+
  geom_text(stat = "count", aes(label = ..count..), vjust = -.5, hjust = 0)
# fct_infreq(Gender) orders factor by increasing frequency.
# Wrapping with fct_rev() reverses it to decreasing order.


## Stacked bar chart
overall_up |> 
  mutate(fagerstrom_baseline = fct_rev(fct_infreq(fagerstrom_catft_0))) |>  # to arrange as per decreasing frequency; for inc. freq remove func fct_rev
  filter(!is.na(fagerstrom_baseline)) |> 
  ggplot( 
       mapping = aes(x = fagerstrom_baseline, fill = tobacco_type)) + 
  geom_bar() 

# The stacked bar chart can also be presented in terms of proportion by specifying the position = 'fill' in geom_bar() function.
overall_up |> 
  mutate(fagerstrom_baseline = fct_rev(fct_infreq(fagerstrom_catft_0))) |>  # to arrange as per decreasing frequency; for inc. freq remove func fct_rev
  filter(!is.na(fagerstrom_baseline)) |> 
  ggplot( 
    mapping = aes(x = fagerstrom_baseline, fill = tobacco_type)) +
  geom_bar(position = "fill")+
  scale_fill_manual(                       # To manually set the colours
    values = c(
      "smoker" = "#E74C3C",      # Red
      "chewer" = "#3498DB"      # Blue  
    ),
    name = "Tobacco type"
  )+
  labs(y = "Proportion") 


overall_up |> 
  mutate(fagerstrom_baseline = fct_rev(fct_infreq(fagerstrom_catft_0))) |>  # to arrange as per decreasing frequency; for inc. freq remove func fct_rev
  filter(!is.na(fagerstrom_baseline)) |> 
  ggplot( 
    mapping = aes(x = fagerstrom_baseline, fill = tobacco_type)) +
  geom_bar(position = "fill")+
  labs(y = "Percentage")+
  scale_y_continuous(labels = scales::percent)+  # To print the labels as percentages, use scale_y_continuous(labels = scales::percent).
  scale_fill_viridis_d()  #  applies the viridis color palette to discrete (categorical) fill aesthetics. It's colorblind-friendly and prints well in grayscale.


# Instead of stacked bar chart we can make the side by side bars for grouping variable by specifying the position = position_dodge() argument to geom_bar() function:
overall_up |> 
  mutate(fagerstrom_baseline = fct_rev(fct_infreq(fagerstrom_catft_0))) |>  # to arrange as per decreasing frequency; for inc. freq remove func fct_rev
  filter(!is.na(fagerstrom_baseline)) |> 
  ggplot( 
    mapping = aes(x = fagerstrom_baseline, fill = tobacco_type)) +
  geom_bar(position = "dodge")+
  scale_fill_brewer(palette = "Dark2")
#Applies the "Dark2" qualitative color palette from the ColorBrewer set.
#This palette is designed for categorical variables and provides distinct, colorblind-friendly colors.


## Moreover, if you want to provide the gap among bars within a category, you need to specify the position = position_dodge2() argument to geom_bar() function:

overall_up |> 
  mutate(fagerstrom_baseline = fct_rev(fct_infreq(fagerstrom_catft_0))) |>  # to arrange as per decreasing frequency; for inc. freq remove func fct_rev
  filter(!is.na(fagerstrom_baseline)) |> 
  ggplot( 
    mapping = aes(x = fagerstrom_baseline, fill = tobacco_type)) +
  geom_bar(position = "dodge2")

## Pie Chart #####

# Calculate percentages for treatment groups
treatment_summary <- overall_up |>
  count(intervention) |>
  mutate(percentage = n / sum(n) * 100)  # Calculate percentages

# Basic pie chart
ggplot(treatment_summary, aes(x = "", y = n, fill = intervention)) +  # x = "": Single bar (empty string) along the x-axis, so all data forms one circular pie.
  geom_bar(stat = "identity", width = 1) +
  coord_polar(theta = "y") +     # Transforms the bar chart into a pie chart by converting the y-axis values into angular coordinates.
  labs(title = "Treatment Group Distribution") +
  theme_void() +
  theme(legend.title = element_blank())

# Create pie chart using coord_polar transformation
ggplot(treatment_summary, aes(x = "", y = n, fill = intervention)) +
  geom_bar(stat = "identity", width = 1, color = "white") +  # Create stacked bar
  coord_polar("y", start = 0) +  # Transform to polar coordinates (pie). start = 0: Starts pie at 12 o'clock position (top)
  scale_fill_manual(values = c("control" = "#E74C3C", "intervention" = "#3498DB")) +
  geom_text(aes(label = paste0(round(percentage, 1), "%")),   #  Shows percentage labels 
            position = position_stack(vjust = 0.5),   # position_stack(vjust = 0.5): Centers text in middle of each slice
            family = "serif", size = 5) +  # Add percentage labels
  labs(title = "Treatment Group Distribution",
       fill = "Group") +
  theme_void(base_family = "serif") +  # Remove axes for clean pie
  theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"))


## Donut chart ####
# Calculate percentages for gender distribution
fuel_type_summary <- overall_up |>
  count(fuel_type) |>
  mutate(percentage = n / sum(n) * 100)

# Create donut chart (pie with hole in center)
ggplot(fuel_type_summary, aes(x = 2, y = n, fill = fuel_type)) +  # x=2 creates the hole
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar("y", start = 0) +
  xlim(0.5, 2.5) +  # Creates the "donut hole" effect. 0.5 = inner radius (empty center). 2.5 = outer radius (ring thickness)
  scale_fill_brewer(palette = "Set2") +  # Use professional color palette
  geom_text(aes(label = paste0(fuel_type, "\n", round(percentage, 1), "%")),
            position = position_stack(vjust = 0.5),
            family = "serif", size = 4) +
  labs(title = "Patient Gender Distribution") +
  theme_void(base_family = "serif") +
  theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
        legend.position = "right")


## Scatterplot ####


overall_long|> 
  filter(!is.na(consumption_per_day)) |> 
ggplot (mapping = aes (x = consumption_per_day, y = sbp))+  
  geom_point()

# change colour, shape & size
overall_long|> 
  filter(!is.na(consumption_per_day)) |> 
  ggplot (mapping = aes (x = consumption_per_day, y = sbp))+  
  geom_point(shape = "square",color="blue",size = 1) # size for point size

# or

overall_long|> 
  filter(!is.na(consumption_per_day)) |> 
  ggplot (mapping = aes (x = consumption_per_day, y = sbp, 
                         shape = time_months, color = time_months))+  
  geom_point(size = 1)


# Add a line through points
overall_long|> 
  filter(!is.na(consumption_per_day)) |> 
  ggplot (mapping = aes (x = consumption_per_day, y = sbp, 
                         shape = time_months, color = time_months))+    
  geom_point(size = 1)+ # size for point size
  geom_smooth(method = "lm", se = FALSE, linewidth = .5) # lm" fits a linear regression line. se=F for no CI

# Facetting 
overall_long|> 
  filter(!is.na(consumption_per_day)) |> 
  ggplot (mapping = aes (x = consumption_per_day, y = sbp, 
                         shape = time_months, color = time_months))+    
  geom_point(size = 1)+ # alpha for transparency
  facet_wrap(~intervention)+  # facetting
  theme_minimal()

#facet grid
overall_long|> 
  filter(!is.na(consumption_per_day)) |> 
  ggplot (mapping = aes (x = consumption_per_day, y = sbp, 
                         shape = time_months, color = time_months))+    
  geom_point(size = 1)+
  facet_grid(fuel_type~intervention)


ggplot(data = overall_up,
       mapping = aes(x=age_of_onset,     
                               y=consumption_per_day_0m,
                               colour=tobacco_type,# different colour for other, male and female i.e. acc to gender
                               shape=intervention, # different shape for different treatment group
                               size= num_tobacco_users))+ # size linked to SysBP_0m systolic bp at 0 month
  geom_point(alpha = .5)+
  theme_minimal()


ggplot(data = overall_up,
       mapping = aes(x=age_of_onset,     
                     y=consumption_per_day_0m,
                     colour=tobacco_type,# different colour for other, male and female i.e. acc to gender
                     shape=intervention, # different shape for different treatment group
                     size= num_tobacco_users))+ # size linked to SysBP_0m systolic bp at 0 month
  geom_point(alpha = .5)+
  labs (color = "Type of tobaccos",   # Results in changed labels in legend
        shape = " Treatment Groups",
        size = "Number of tobacco user at the household")+
theme_minimal()

# Removing legends
ggplot(data = overall_up,
       mapping = aes(x=age_of_onset,     
                     y=consumption_per_day_0m,
                     colour=tobacco_type,# different colour for other, male and female i.e. acc to gender
                     shape=intervention, # different shape for different treatment group
                     size= num_tobacco_users))+ # size linked to SysBP_0m systolic bp at 0 month
  geom_point(alpha = .5)+
  guides(
    size = "none",    # Remove SysBP_0m legend
    colour = "none")+   # Remove Gender legend
  labs (shape = " Treatment Groups")+      # Results in changed labels in legend
  theme_minimal()




##Changing theme elements
# It gets a little bit more complicated when you want to change things like the background of your plot or the font size of your title. 
# There, you will need not only the theme() arguments like plot.title and plot.background, you will also need helper functions. 
# All of these helper functions start with element_. Depending on what you want to change, you will have to use one of

# element_text(),
# element_rect(),
# element_line() or
# element_blank()

ggplot(data = overall_up,
       mapping = aes(x=age_of_onset,     
                     y=consumption_per_day_0m,
                     colour=tobacco_type,# different colour for other, male and female i.e. acc to gender
                     shape=intervention, # different shape for different treatment group
                     size= num_tobacco_users))+ # size linked to SysBP_0m systolic bp at 0 month
  geom_point(alpha = .5)+
  guides(
    size = "none",    # Remove SysBP_0m legend
    colour = "none")+   # Remove Gender legend
  labs (shape = " Treatment Groups")+ 
  labs(title="My New Chart", #labs for labels
       subtitle = "Created with ggplot",
       caption = "copyright(c) R for Public Health",  
       x = "age of onset",    
       y = "consumption per day at baseliine",
       size = "STobacco user at household"
  )+ 
  theme_minimal((base_size = 16))+ # To increase the overall font
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot", # use the plot.title.position and plot.caption.position. Both of these can be set to "plot" to align the titles and captions to the whole plot and not the panel.
    legend.position = "top",  # legend.position. t can be set to "top", "bottom", "left" or "right" or "none".
    plot.title = element_text(
      size = 24, 
      face = "bold", 
      color = "red"
    ),
    plot.background = element_rect(
      fill = "#FAF3E1",
      color = "black",
      linewidth = 3
    ),
    panel.grid.major = element_line(color = "#B3BFFF",  linewidth = 0.5,linetype = "dashed" ) # element_line() does not accept an alpha argument.Transparency must be encoded in the color value itself.
  )

## Modifying scales
## If you want, you could even try to modify the x and y scale layers. For example, you could try setting

# limits (range of axis),
# breaks (where to place labels) and
# labels (actual labels)

ggplot(data = overall_up,
       mapping = aes(x=age_of_onset,     
                     y=consumption_per_day_0m,
                     colour=tobacco_type,# different colour for other, male and female i.e. acc to gender
                     shape=intervention, # different shape for different treatment group
                     size= num_tobacco_users))+ # size linked to SysBP_0m systolic bp at 0 month
  geom_point(alpha = .5)+
  guides(
    size = "none",    # Remove SysBP_0m legend
    colour = "none")+   # Remove Gender legend
  labs (shape = " Treatment Groups")+ 
  labs(title="My New Chart", #labs for labels
       subtitle = "Created with ggplot",
       caption = "copyright(c) R for Public Health",  
       x = "age of onset",    
       y = "consumption per day at baseliine",
       size = "STobacco user at household"
  )+ 
  theme_minimal((base_size = 16))+ # To increase the overall font
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot", # use the plot.title.position and plot.caption.position. Both of these can be set to "plot" to align the titles and captions to the whole plot and not the panel.
    legend.position = "top",  # legend.position. t can be set to "top", "bottom", "left" or "right" or "none".
    plot.title = element_text(
      size = 24, 
      face = "bold", 
      color = "red"
    ),
    plot.background = element_rect(
      fill = "#FAF3E1",
      colour = "black",
      linewidth = 3
    ),
    panel.grid.major = element_line(color = "#B3BFFF",  size = 0.5, ) # element_line() does not accept an alpha argument.Transparency must be encoded in the color value itself.
  ) +
  scale_x_continuous(
    limits = c(18, 30),
    breaks = c(18, 24, 30),
    label = c("18","24","30")
  )





?theme()
?ggtheme

##Box plot ####

# Box plot- one continuous

ggplot(data = overall_up, mapping = aes(x = "", y = current_age)) +
  geom_boxplot() +
  labs(x = "", y = "Age")


# Box plot- one continuous and one discrete 

ggplot(data = overall_long, mapping = aes(x = time_months, 
                                y= sbp))+
  geom_boxplot()



# To change the width of the boxes we have to specify the width argument to geom_boxplot() as:
ggplot(data = overall_long, mapping = aes(x = time_months, 
                                          y= sbp))+
  geom_boxplot(width = 0.3, color = "red", fill = "orange")

# The mean of the continuous variable within each class of a factor variable can also be added by means of stat_summary() function as:
ggplot(data = overall_long, mapping = aes(x = time_months, 
                                          y= sbp))+
  geom_boxplot(width = 0.3, color = "red", fill = "orange", alpha = 0.5)+
  stat_summary(fun.y = mean, geom = "point", color = "black", shape = 10, size = 2) # shape = 10: Cross symbol

# These vertical box plot can also be made horizontally
ggplot(data = overall_long, mapping = aes(x = time_months, 
                                          y= sbp))+
  geom_boxplot(width = 0.3, color = "red", fill = "orange", alpha = 0.5)+
  stat_summary(fun.y = mean, geom = "point", color = "black", shape = 10, size = 2)+  # fun.y and fun are equivalent
  coord_flip()

# Create faceted box plots: Cholesterol by Region and Gender

ggplot(data = overall_long, 
       mapping = aes(x = time_months,y= sbp, fill = factor(intervention)))+
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 18, 
               size = 3, color = "red") +
  facet_wrap(~ tobacco_type, ncol = 2) +  # Split by Region
  labs(title = "Cholesterol Levels by Gender Across Regions",
       subtitle = "Faceted box plots reveal regional patterns | Red diamond = mean",
       x = "Gender",
       y = "Total Cholesterol (mg/dL)") +
  scale_fill_manual(values = c("0" = "#4DBBD5", "1" = "#E64B35")) +
  theme_minimal() +
  theme(legend.position = "none",
        strip.background = element_rect(fill = "gray90", color = "black"),
        strip.text = element_text(face = "bold", size = 11))

## jitter plot####
ggplot(data = overall_long, 
       mapping = aes(x = time_months,
                     y= sbp,
                     color = wealth_quintile))+
  geom_jitter(size = 2)

# Jitter points with boxplot
ggplot(data = overall_long, mapping = aes(x = time_months, 
                                          y= sbp))+
  geom_jitter(width = 0.2, color = "red") +
  geom_boxplot(width = 0.3, color = "black", fill = "orange", alpha = 0.5)

## Violin plot####
ggplot(data = overall_long, mapping = aes(x = time_months, 
                                          y= sbp))+ # Add fill=Vaccinated
  geom_violin()

# Create violin plot: BMI distribution by Gender

p1 <- ggplot(data = overall_long, 
       mapping = aes(x = time_months,
                     y= consumption_per_day,
                     fill = factor(intervention)))+
  geom_violin(trim = FALSE,        # Don't trim tails
              alpha = 0.7) +       # Transparency
  geom_boxplot(width = 0.1,       # Add boxplot inside
               fill = "white",
               outlier.shape = NA) + # Hide outliers (shown in violin)
  stat_summary(fun = mean,         # Add mean point
               geom = "point",
               shape = 18,
               size = 3,
               color = "black") +
  labs(title = "Consumption per day by time and group of intervention",
       subtitle = "Violin plot shows full distribution shape",
       x = "Time",
       y = "Consumption per day",
       fill = "Intervention") +
  scale_fill_manual(values = c("0" = "#4DBBD5", "1" = "#E64B35")) +
  theme_minimal() +
  theme(legend.position = "bottom")

p1 
# Create violin plot comparing sbpacross regions
p2 <- ggplot(data = overall_long, 
       mapping = aes(x = time_months,
                     y= sbp))+
  geom_violin(alpha = 0.7, trim = FALSE) +  # Create violin shapes
  geom_boxplot(width = 0.15, alpha = 0.5, outlier.shape = NA) +  # Add boxplot inside
  scale_fill_brewer(palette = "Set2", name = "time (months)") +  # Color palette
  labs(title = "SBPBMI Distribution by time (Violin Plot)",
       x = "Time (months)", y = "SBP") +
  theme_minimal(base_family = "serif") +
  theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
        axis.title = element_text(size = 12),
        legend.position = "none")  # X-axis labels regions

p2

## Save the plot ###
ggsave(
  filename = "cons_p_day.png", # png better than jpeg
  plot = p1,
  width = 8, # default is in inches
  height = 6,
  dpi = 300
)

ggsave(
  filename = "sbp_plot.jpeg",
  plot = p2,
  width = 24,
  height = 18,
  dpi = 300,
  units  = "cm" # accepted units are "cm", "in", "mm" or "px"
)

ggsave(
  filename = "sbp_plot.pdf", #vector graphics, journal friendly
  plot = p2,
  width = 8,
  height = 6
)

saveRDS(p1, "consump_per_day.rds")

rm(list = setdiff(ls(),list("overall_age_u", "data_dic","overall_long", "overall_up")))


