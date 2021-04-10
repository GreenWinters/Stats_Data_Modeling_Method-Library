#Green Winters

##Concentrations of the pollutants aldrin and hexachlorobenzene 
# (HCB) in nanograms per liter
surface <- c(3.74, 4.61, 4.00, 4.67, 4.87, 5.12, 4.52, 5.29, 5.74, 5.48)
bottom <- c(5.44, 6.88, 5.37, 5.44, 5.03, 6.48, 3.89, 5.85, 6.85,7.16)

#observations are independent normal random variables with unknown depth-specific
# means Qs and Qb and precisions Rs and Rb

#prior can be treated as the product of two normal-gamma priors
mu0 <-  0
k0 <-  0
alpha <- -.5 #As opposed to v_0/2
beta <- Inf  #As opposted to v_0/2*sigma_0^2
theta <- seq(4,6.5, length.out = 250)

#Find the joint posterior distribution for the parameters 
#(theta_s, P_s, theta_b, P_b). 


##Surface
n.surface <- length(surface)
xbar.surface <- mean(surface)
s2.surface <-var(surface)

muStar.surface <- ((k0*mu0)+(n.surface*xbar.surface))/(k0+n.surface)
kStar.surface <- k0+n.surface
alphaStar.surface <- alpha + (n.surface/2)
betaStar.surface <- 1/((1/beta)+((sum((surface-xbar.surface)^2))*.5)+
  ((n.surface*k0)/(n.surface+k0)*2)*(xbar.surface-mu0)^2)
s2Star.Surface <- 1/sqrt(alphaStar.surface*kStar.surface)


plot(theta, dgamma(theta,shape=alphaStar.bottom,scale = betaStar.bottom)*dnorm(theta,muStar.bottom,s2Star.bottom),
     ylab = "Joint Probability Density", type = "l",
     main = "Normal-Gamma Joint Posterior Distribution for BOTTOM",
     xlab="Mean", 
     col="red")

##Bottom
n.bottom <- length(bottom)
xbar.bottom <- mean(bottom)
s2.bottom <-var(bottom)

muStar.bottom <- ((k0*mu0)+(n.bottom*xbar.bottom))/(k0+n.bottom)
kStar.bottom <- k0+n.bottom
alphaStar.bottom <- alpha + (n.bottom/2)
betaStar.bottom <- 1/((1/beta)+((sum((bottom-xbar.bottom)^2))*.5)+
                         ((n.bottom*k0)/(n.bottom+k0)*2)*(xbar.bottom-mu0)^2)
s2Star.bottom <- 1/sqrt(alphaStar.bottom*kStar.bottom)



plot(theta, dgamma(theta,shape=alphaStar.surface,scale = betaStar.surface )*dnorm(theta,muStar.surface,s2Star.Surface),
     ylab = "Joint Probability Density", type = "l",
     main = "Normal-Gamma Joint Posterior Distribution for SURFACE",
     xlab="Mean", 
      col="blue")


#Find 90% posterior credible intervals for Qs, Qb, Rs, and Rb. 

#Credible Intervals for Precision
qgamma(c(.05,.95),shape=alphaStar.bottom,scale = betaStar.bottom)
qgamma(c(.05,.95),shape=alphaStar.surface,scale = betaStar.surface)

#90% posterior credible intervals for Theta/Mean
#Bottom
lowerbound.bottom=muStar.bottom+qt(0.05,2*alphaStar.bottom)/sqrt(kStar.bottom*alphaStar.bottom*betaStar.bottom) 
upperbound.bottom=muStar.bottom+qt(0.95,2*alphaStar.bottom)/sqrt(kStar.bottom*alphaStar.bottom*betaStar.bottom) 
#Surface
lowerbound.surface=muStar.surface+qt(0.05,2*alphaStar.surface)/sqrt(kStar.surface*alphaStar.surface*betaStar.surface) 
upperbound.surface=muStar.surface+qt(0.95,2*alphaStar.surface)/sqrt(kStar.surface*alphaStar.surface*betaStar.surface) 


# Use direct Monte Carlo to sample 10,000 observations from the joint posterior distribution

#Surface
s2Post.surface <- rgamma(10000,shape = alphaStar.surface,scale = betaStar.surface)
theta.surface <- rnorm(10000, muStar.surface, sqrt(s2Post.surface/kStar.surface))

#Bottom
s2Post.bottom <- rgamma(10000,shape = alphaStar.bottom,scale = betaStar.bottom)
theta.bottom <- rnorm(10000, muStar.bottom, sqrt(s2Post.surface/kStar.bottom))

#Credible Intervals of Monte Carlo Samples
quantile(theta.surface, c(.05,.95))
quantile(theta.bottom, c(.05,.95))


# estimate the probability that the mean bottom concentration
# Qb is higher than the mean surface concentration Qs
n <- 10000
prob.mean <- sum(theta.bottom>theta.surface)/n

prob.std <- sum(s2Post.bottom>s2Post.surface)/n


