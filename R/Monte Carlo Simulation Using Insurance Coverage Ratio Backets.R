#Install Tidyverse via Install Packages under Tools...It takes a while.
#Clear Global Enviornment
rm(list=ls())


ladata <- read.csv(".csv")
library(ggplot2)
library(utils)

payRatio <-ladata$Payout/ladata$Coverage
ladata <- cbind(ladata,payRatio)
coverage.avg <- mean(ladata$Coverage)
payRatio.avg <- mean(ladata$payRatio)
payout.avg <- mean(ladata$Payout) 
#payout.avg = 89,620.04
#payRatio.avg = 0.5053351
#coverage.avg = 196,567.1
payout.sd <- sd(ladata$Payout)
payRatio.sd <- sd(ladata$payRatio)
coverage.sd <- sd(ladata$Coverage)
#payout.sd = 73,190.59
#payRatio.sd = 0.3017835
#coverage.sd = 111,575.1
x <- ladata[ladata$Coverage<=50000,]
y <-ladata[ladata$Coverage>50000 & ladata$Coverage<150000,]
z <- ladata[ladata$Coverage>=150000,]
mean(x$payRatio)
#Average (Pay/Cov) for equal to and less than 50K Coverage = 0.7803036
mean(y$payRatio)
#Average (Pay/Cov) for more than 150K and less than 150K Coverage = 0.5855553
mean(z$payRatio)
#Average (Pay/Cov) for equal to and more than 150K Coverage= 0.4374974
less50kpayratio.avg <- mean(x$payRatio)
more50kpayratio.avg <- mean(y$payRatio)
more150kpayratio.avg <- mean(z$payRatio)
less50kpayratio.sd <- sd(x$payRatio)
more50kpayratio.sd <- sd(y$payRatio)
more150kpayratio.sd <- sd(z$payRatio)
less50kpayout.avg <- mean(x$Payout)
more50kpayout.avg <- mean(y$Payout)
more150kpayout.avg <- mean(z$Payout)
less50kcoverage.avg <- mean(x$Coverage)
more50kcoverage.avg <- mean(y$Coverage)
more150kcoverage.avg <- mean(z$Coverage)
#random number generator for exponential variate rexp(#, rate=#)
#set variable as the number of interations
iteration.num <- 500
#set bounds of the number of expected claims
claimCieling <- 99750
claimfloor <-80000
#Calculate average and standard deviation of cieling floor and ceiling 
claimNum <- claimfloor+claimCieling
claimNumSd <- sqrt((((claimNum-claimCieling)^2) + ((claimNum-claimfloor)^2))/2)
#Take an average of the bounds for the expected number of claims for the event
ClaimNumAvg <- (claimNum)/2
#Explore the data, determine the percentage of events that were CWOP 
#and create a range of random numbers around that percentage.
payout0 <- ifelse(ladata$payRatio==0,1,0)
#OR payout0 <- mean(ladata$Payout==0)
mean(payout0)
#0
cwopRand <- runif(1, min=0, max=.03)
#While also exploring the data, determine the standard deviation and percentage(mean) of claims with 100% payout
payout100 <- ifelse(ladata$payRatio==1,1,0)
#OR mean(ladata$payRatio==1)
mean(payout100)
#0.1070603 ~ 10.7% of the claims had 100% payout
#Create a variable that generates a random number based on the proportion and standard deviation of the claims with 100% payout
pay100Rand <- runif(1, min=.09, max=.12)
#set a variable to equal the maximum claim payout based on coverage limits
MaxClaimAmt <- 10^6
create.iteration.list <- function() {
  less50Kclaim.list <-list()
  more50Kclaim.list <-list()
  more150Kclaim.list <-list()
  #create variable that passes the object for GUI progress bar of the loop command. Min and max should reflect the number of iterations
  progress <- winProgressBar(title = "Progress Bar", min=0, max=500, width = 300)
  iteration.num <- max(claimfloor, rnorm(1, mean = ClaimNumAvg, sd = claimNumSd))
  for(x in 1:iteration.num) {
    pickDist <- runif(1, min=1, max = 3)
    pickDist <- as.integer(pickDist)
    #generate a random integers between 1 & 3, repeats are allowed.
    if (pickDist==1) {
      #Creates a random claim's payout ratio between 0% and 100%
      claim.stat <- runif(1, min = 0, max = 1)
      if (claim.stat > cwopRand) {
        #And if the claim is not a CWOP
        if (claim.stat > (1-pay100Rand)) {
          #if the claim's payout is within the probability range of 100% payout
          iteration.cov <- less50kpayout.avg
          iteration.ratio <- 1
          less50Kclaim.list <- c(less50Kclaim.list, min(iteration.ratio*iteration.cov, 50000))
        } else {
          iteration.cov <- less50kpayout.avg
          iteration.ratio <- max(0, rnorm(1, mean=less50kpayratio.avg, sd=less50kpayratio.sd))
          less50Kclaim.list <- c(less50Kclaim.list, min(iteration.cov*iteration.ratio, 50000))}
      } 
    } else if(pickDist==2) {
      claim.stat <- runif(1, min = 0, max = 1)
      if (claim.stat > cwopRand) {
        #And if the claim is not a CWOP
        if (claim.stat > (1-pay100Rand)) {
          #if the claim's payout is within the random probability of 100% payout
          iteration.cov <- more50kpayout.avg
          iteration.ratio <- 1
          more50Kclaim.list <- c(more50Kclaim.list, min(iteration.ratio*iteration.cov, 150000))
        } else {
          iteration.cov <- more50kpayout.avg
          iteration.ratio <- max(0, rnorm(1, mean=more50kpayratio.avg, sd=more50kpayratio.sd))
          more50Kclaim.list <- c(more50Kclaim.list, min(iteration.cov*iteration.ratio, 150000))}}
    } else { 
      claim.stat <- runif(1, min = 0, max = 1)
      if (claim.stat > cwopRand) {
        #And if the claim is not a CWOP
        if (claim.stat > (1-pay100Rand)) {
          #if the claim's payout is within the random probability of 100% payout
          iteration.cov <- more150kpayout.avg
          iteration.ratio <- 1
          more150Kclaim.list <- c(more150Kclaim.list, min(iteration.ratio*iteration.cov, MaxClaimAmt))
        } else {
          iteration.cov <- more150kpayout.avg
          iteration.ratio <- max(0, rnorm(1, mean=more150kpayratio.avg, sd=more150kpayratio.sd))
          more150Kclaim.list <- c(more150Kclaim.list, min(iteration.cov*iteration.ratio, MaxClaimAmt))}}}
  }
  #The rest of the progress bar code
  progression <- x
  #x is the arguement in the loop statement
  setWinProgressBar(progress, progression, title=paste(round(progression/iteration.num)*100,"% done"))
  #Output for each bucket. For some reason ploting functions don't take lists.
  less50Kclaim.list <- unlist(less50Kclaim.list)
  plot.ecdf(less50Kclaim.list, main = "Empirical Cumulative Distributive Function of Claims Less than $50K")
  hist(less50Kclaim.list, main = "Simulation: Freq Histogram of Claim Payout Less than $50K", xlab = "Payout ($)")
  hist(less50Kclaim.list, probability = TRUE, main = "Simulation: Probability Histogram of Claim Payoutout Less than $50K", xlab = "Payout ($)")
  #
  more50Kclaim.list <- unlist(more50Kclaim.list)
  plot.ecdf(more50Kclaim.list, main = "Empirical Cumulative Distributive Function of Claims More than $50K and Less than $150K")
  hist(more50Kclaim.list, main = "Simulation: Freq Histogram of Claim Payout More than $50K and Less than $150K", xlab = "Payout ($)")
  hist(more50Kclaim.list, freq = FALSE, main = "Simulation: Probability Histogram of Claim Payout More than $50K and Less than $150K", xlab = "Payout ($)")
  #
  more150Kclaim.list <- unlist(more150Kclaim.list)
  plot.ecdf(more150Kclaim.list, main = "Empirical Cumulative Distributive Function of Claims More than $150K")
  hist(more150Kclaim.list, main = "Simulation: Freq Histogram of Claim Payout More than $150K", xlab = "Payout ($)")
  hist(more150Kclaim.list, freq = FALSE, main = "Simulation: Probability Histogram of Claim Payout More than $150K", xlab = "Payout ($)")
}
