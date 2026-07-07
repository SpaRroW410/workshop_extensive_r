

# Variables


#Categorical variables

c("Red", "Blue", "Green") -> colors
##factor
# value - levels and labels
gender <- factor(c("Male", "Female", "Male", "Female", "Other"), 
                 levels = c("Male","Female","Other"))

physical_activity <- sample(c(1,2),100, replace = TRUE)
physical_activity <- factor(physical_activity, levels = c(1,2), 
                            labels = c("Yes", "No"))


##dichotomous
yes_no <- sample(c("yes","no"),100, replace = TRUE)

# Numerical variable

#Integer
2L
is.integer(2L)
is.double(2L)
is.numeric(2L)

#Decimal (Double)
1.05
is.numeric(1.05)
is.integer(1.05)


int <- c(1L: 10L)

#Logical 
c(T, TRUE, F, FALSE, NA)


#function
?rnorm

?is.numeric

rnorm(3)

rnorm(3,10,2)

rnorm(10)

?mean

mean(rnorm(10))

mean(rnorm(100))

x <- 1-.05/2
qnorm(1 - .05/2)

?seq
seq(1,100,3)

seq(1,2, length.out = 10)


# Concatenate two strings
## paste and paste0

# Concatenating with a space
result <- paste("Hello", "world", "How?",sep = " ")
print(result)
result

# Concatenating without a separator
result <- paste0("Hello", "world")
print(result)

#list
my_list <- list(name = "Alice", age = 25, scores = c(90, 85, 88))
my_list
my_list$scores

#matrix
my_matrix <- matrix(1:6, nrow = 2, ncol = 3)
print(my_matrix)

#dataframe
# Create sample data with 100 observations


ID <- 1:100
Name <- sample(c("Alice", "Bob", "Charlie", "David", "Eva"), 100, replace = TRUE)
Age <- sample(20:50, 100, replace = TRUE)
Height <- sample(150:190, 100, replace = TRUE)
Score <- sample(60:100, 100, replace = TRUE)

# Combine lists into a dataframe
sample_data <- data.frame(
  ID = ID,
  Name = Name,
  Age = Age,
  Height = Height,
  Score = Score
)

# Display the first few rows of the dataframe
head(sample_data)
summary(sample_data)
dim(sample_data)
colnames(sample_data)
dplyr::glimpse(sample_data)





