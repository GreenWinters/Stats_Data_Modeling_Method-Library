#Green Winters



# Concentrations of the pollutants aldrin and hexachlorobenzene 
# (HCB) in nanograms per liter
surface <- c(3.74, 4.61, 4.00, 4.67, 4.87, 5.12, 4.52, 5.29, 5.74, 5.48)
bottom <- c(5.44, 6.88, 5.37, 5.44, 5.03, 6.48, 3.89, 5.85, 6.85,7.16)

n <- 200 #length of distribution 

# Surface Readings Parameters
n.surface <- length(surface)
xbar.surface <- mean(surface)
s2.surface <-var(surface)

# Bottom Readings Parameters
n.bottom <- length(bottom)
xbar.bottom <- mean(bottom)
s2.bottom <-var(bottom)


#normal distribution parameters for estimating unknown surface and bottom theta
theta.mu <- 6
theta.tau <- 1.5 #tau or sigma^2
k0 <- 0

#95% credible interval for unknown surface and bottom theta
lowerbound.theta <- 3
upperbound.theta <- 9
theta.grid <- seq(lowerbound.theta,upperbound.theta, length.out = n)


#95% credible interval stats for unknown surface and bottom std
sigma.lowerbound.std <- 0.75
sigma.upperbound.std <- 2.0
std.grid <- seq(sigma.lowerbound.std, sigma.upperbound.std, length.out = n)


#gamma parameters for estimating unknown surface and bottom precision
precision.alpha <- 4.5
precision.scale <- 0.19


#95% credible interval stats for unknown surface and bottom precision
#prec = 1/sigma^(-2)
precision.lowerbound.prec <- 0.25
precision.upperbound.prec <- 1.8
precision.grid <- seq(precision.lowerbound.prec, precision.upperbound.prec, length.out = n)


#Surface Posterior Parameters
muStar.surface <- ((theta.mu/(theta.tau^2))+sum(surface)/s2.surface)/((1/theta.tau^2)+(n.surface/s2.surface))
s2Star.Surface <- 1/sqrt((1/theta.tau^2)+(n.surface/s2.surface))

kstar.surface <- k0+n.surface

alphaStar.surface <- precision.alpha + (n.surface/2)
betaStar.surface <- 1/((1/precision.scale)+(sum((surface-xbar.surface)^2)*.5))



#Bottom Posterior Parameters
muStar.bottom <- ((theta.mu/(theta.tau^2))+sum(bottom)/s2.bottom)/((1/theta.tau^2)+(n.bottom/s2.bottom))
s2Star.bottom <- 1/sqrt((1/theta.tau^2)+(n.bottom/s2.bottom))

kstar.bottom <- k0+n.bottom

alphaStar.bottom <- precision.alpha + (n.bottom/2)
betaStar.bottom <- 1/((1/precision.scale)+(sum((bottom-xbar.bottom)^2)*.5))

s2Star.bottom <- 1/sqrt(alphaStar.bottom*kStar.bottom)


### The conditional distribution for Theta_surface given the other parameters and the observations.
theta.conditional.surface <- dnorm(theta.grid,muStar.surface,s2Star.Surface)

plot(theta.grid,theta.conditional.surface,
     xlab="Mean",
     col="black",
     xlim = c(4,6),
     ylab=expression(paste(theta,"|",rho)), 
     main="Conditional Density of Surface Mean Given Precision")



# The conditional distribution for Theta_bottom given the other parameters and the observations.
theta.conditional.bottom <- dnorm(theta.grid,muStar.bottom,s2Star.bottom)
                                   
plot(theta.grid,theta.conditional.bottom,
     xlab="Mean",
     col="blue",
     ylab=expression(paste(theta,"|",rho)),
     xlim = c(5,6.75),
     main="Conditional Density of Bottom Mean Given Precision")



# The conditional distribution for ThetaTheta_surface given the other parameters and the observations.
precision.surfacegrid <- seq(.25, 2.5, length.out = n) #Extend the distribution farther than provided 95% CI 

precision.conditional.surface <- dgamma(precision.surfacegrid,shape=alphaStar.surface,scale=betaStar.surface)

  
plot(precision.surfacegrid,precision.conditional.surface,
     xlab="Precision",
     col="violet",
     ylab=expression(paste(rho,"|",theta)),
     main="Conditional Density of Surface Precision Given Mean")


# The conditional distribution for ThetaTheta_bottom given the other parameters and the observations.
precision.conditional.bottom <- dgamma(precision.grid,shape=alphaStar.bottom,scale=betaStar.bottom)


plot(precision.grid,precision.conditional.bottom,
     xlab="Precision",
     col="red",
     ylab=expression(paste(rho,"|",theta)),
     main="Conditional Density of Bottom Precision Given Mean")



#Using the distributions you found in Part 1, draw 10,000 Gibbs samples of (Theta_surface, Theta_bottom, ThetaTheta_surface, ThetaTheta_bottom)

#Initialize starting parameters
precision.gibbs.surface = theta.gibbs.surface = sigma.gibbs.surface = NULL   
precision.prev.gibbs.surface <- s2Star.Surface

# SURFACE GIBBS SIMULATION
for(i in 1:10000)
  {
  #Update mu_star
  muStar.gibbs <- ((theta.mu/(theta.tau^2))+sum(surface)/precision.prev.gibbs)/((1/theta.tau^2)+(n.surface/precision.prev.gibbs))
  
  #Update tau_star
  s2Star.gibbs <- 1/sqrt((1/theta.tau^2)+(n.surface/precision.prev.gibbs))
  
  #Get theta 
  theta.gibbs.surface[i] <- rnorm(1,muStar.gibbs,s2Star.gibbs)
  
  #Update beta with simulated theta 
  betaStar.gibbs <- 1/((1/precision.scale)+(sum((surface-theta.gibbs.surface[i])^2)*.5))
  
  #Get precision/rho
  precision.gibbs.surface[i] <- rgamma(1,shape = alphaStar.surface, scale = betaStar.gibbs)
  
  #Get sigma
  sigma.gibbs.surface[i] <-  1/sqrt(precision.gibbs.surface[i]) 
  
  #Update precision for next iteration
  precision.prev.gibbs.surface <- precision.gibbs.surface[i] 
  } 


plot(theta.gibbs.surface,precision.gibbs.surface,
     col="salmon1",
     ylab=expression(rho),
     xlab=expression(theta),
     main="Gibbs Simulation Samples of Surface Data")


#Initialize starting parameters
precision.gibbs.bottom = theta.gibbs.bottom = sigma.gibbs.bottom = NULL   
precision.prev.gibbs.bottom <- s2Star.bottom

# BOTTOM GIBBS SIMULATION
for(i in 1:10000)
  {
  # Update mu_star
  muStar.gibbs <- ((theta.mu/(theta.tau^2))+sum(bottom)/precision.prev.gibbs)/((1/theta.tau^2)+(n.bottom/precision.prev.gibbs))
  
  # Update tau_star
  s2Star.gibbs <- 1/sqrt((1/theta.tau^2)+(n.bottom/precision.prev.gibbs))
  
  # Get theta 
  theta.gibbs.bottom[i] <- rnorm(1,muStar.gibbs,s2Star.gibbs)
  
  # Update beta with simulated theta 
  betaStar.gibbs <- 1/((1/precision.scale)+(sum((bottom-theta.gibbs.bottom[i])^2)*.5))
  
  # Get precision/rho
  precision.gibbs.bottom[i] <- rgamma(1,shape = alphaStar.bottom, scale = betaStar.gibbs)
  
  # Get sigma
  sigma.gibbs.bottom[i] <-  1/sqrt(precision.gibbs.bottom[i]) 
  
  # Update precision for next iteration
  precision.prev.gibbs.bottom <- precision.gibbs.bottom[i] 
  }


plot(theta.gibbs.bottom, precision.gibbs.bottom,
     col="seagreen3",
     ylab=expression(rho),
     xlab=expression(theta),
     main="Gibbs Simulation Samples of Bottom Data")



# Estimate 90% Credible Intervals 
# Theta Surface
quantile(theta.gibbs.surface, probs = c(.05,.95))

# Theta Bottom
quantile(theta.gibbs.bottom, probs = c(.05,.95))

# Standard Deviation Surface
quantile(sigma.gibbs.surface, probs = c(.05,.95))

# Standard Deviation Bottom
quantile(sigma.gibbs.bottom, probs = c(.05,.95))

# Theta Bottom - Theta Surface
quantile(theta.gibbs.bottom-theta.gibbs.surface, probs = c(.05,.95))


quantile(precision.gibbs.surface, probs = c(.05,.95))
quantile(precision.gibbs.bottom, probs = c(.05,.95))



# Do a traceplot of Theta_s - Theta_b
library(coda)
# Traceplot theta_bottom - theta_surface
traceplot(as.mcmc(theta.gibbs.bottom-theta.gibbs.surface), 
          col="firebrick",
          main="Traceplot for Gibbs Sampling Estimate of\nDifference in Bottom and Surface Theta")


# Auto Correlation Function
library(stats)
acf(theta.gibbs.bottom-theta.gibbs.surface)
pacf(theta.gibbs.bottom-theta.gibbs.surface, plot=FALSE)

# Calculate effective sample size for Gibbs
effectiveSize(theta.gibbs.bottom-theta.gibbs.surface)

# Recreate Monte Carlo from Assignment 6
#Surface
s2Post.surface <- rgamma(10000, shape = alphaStar.surface, scale=betaStar.surface)
theta.MonteCarlo.surface <- rnorm(10000, muStar.surface, s2Post.surface)

#Bottom
s2Post.bottom <- rgamma(10000, shape = alphaStar.bottom, scale=betaStar.bottom)
theta.MonteCarlo.bottom <- rnorm(10000, muStar.bottom, s2Post.bottom)

# Calculate effective sample size for Monte Carlo
effectiveSize(theta.MonteCarlo.bottom-theta.MonteCarlo.surface)







