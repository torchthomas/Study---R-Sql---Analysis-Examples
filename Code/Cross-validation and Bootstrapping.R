# Cross-validation and bootstrapping
#.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Clear vars/mem,set notation and other limits
rm(list=ls()); gc(); options(digits= 7)
options(scipen=999) # turn off scientific notation

# Make functions to read in all needed packages 
readInPackages= function(packages){
    #for reading in packages
    packsInstalling <- packages[!packages %in% installed.packages()]
    for(lib in packsInstalling) install.packages(lib,dependencies= TRUE)
    sapply(packages,require,character=TRUE)
}
# Load packages       
packages <- c(
    "stats",#for contrasts fn
    "ISLR",#for data Smarket(i.e.,stock market)
    "class",#for knn()
    "boot",#for bootstrapping
    "MASS"#,#for lda,qda
)
readInPackages(packages)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# We look at cross-validation here,using OLS,LOOCV,bootstrap,and 
# other variants
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Cross-validation base test with OLS 
#Training first; Using auto data we follow procedure in gareth et al 2014 5.3 lab
library(ISLR); attach(Auto);
set.seed(1)
train <- sample(392,196)

#fit linear regression(for comparison,analysis,reference)
lm.fit=lm(mpg ~ horsepower,data=Auto,subset=train )
    mean((mpg -predict(lm.fit,Auto))[-train ]^2)

    
#prediction is for all 392 obns.
#poly is for the estimation of the test error for the polynom.and cub.regs   
lm.fit2=lm(mpg~poly(horsepower,2),data=Auto,subset=train )
    mean((mpg -predict(lm.fit2,Auto))[-train ]^2)

lm.fit3=lm(mpg~poly(horsepower,3),data=Auto,subset=train )
    mean((mpg -predict(lm.fit3,Auto))[-train ]^2)

set.seed(2)
train=sample(392,196)

lm.fit=lm(mpg~horsepower,subset=train)
mean((mpg-predict(lm.fit,Auto))[-train ]^2)

lm.fit2=lm(mpg~poly(horsepower,2),data=Auto,subset=train )
mean((mpg-predict(lm.fit2,Auto))[-train ]^2)

lm.fit3=lm(mpg~poly(horsepower,3),data=Auto,subset=train)
mean((mpg-predict(lm.fit3,Auto))[-train ]^2)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Leave one out(LOO) Cross-validation
    #will use bootstrapping so call that library
    library(boot)
#first glm is without family argument and we compare to ols results
glm.fit=glm(mpg ~ horsepower,data=Auto)
coef(glm.fit)

lm.fit=lm(mpg~horsepower,data=Auto)
coef(lm.fit) #39.936,-.158

glm.fit=glm(mpg ~ horsepower,data=Auto)
cv.err=cv.glm(Auto,glm.fit)
cv.err$delta

#had an error for file formatting
tools::showNonASCIIfile("C:/Users/tdevine/Box Sync/learning/projects/Code Statistical Learning/Cross-validation and Bootstrapping.R")

cv.error=rep(0,5)
for(i in 1:5){
    glm.fit=glm(mpg~poly(horsepower,i),data=Auto)
    cv.error[i]=boot::cv.glm(Auto,glm.fit)$delta[1]
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#k-fold cross-validation
set.seed(17)
cv.error.10= rep(0,10)
for (i in 1:10) {
    glm.fit=glm(mpg~poly(horsepower,i),data=Auto)
    cv.error.10[i]=boot::cv.glm(Auto,glm.fit,K=10)$delta[1]
}
cv.error.10

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#BOOTSTRAP
alpha.fn=function(data,index){
     X=data$X[index]
     Y=data$Y[index]
     return ((var(Y)-cov(X,Y))/(var(X)+var(Y)-2*cov(X,Y)))
     }
alpha.fn(Portfolio,1:100)

set.seed(1)
alpha.fn(Portfolio,sample(100,100,replace=T))

#Actual bootstrap with 1000 boostrap estimates for out parameter alpha
(theboot= boot::boot(Portfolio,alpha.fn,R=1000))
    #estimate: alphahat      = 0.5758
    #          sigma_alphahat= 0.0886

#Get estimates from a fn which we get the coefs from
boot.fn=function(data,
             index) return(coef(lm(mpg~horsepower,data=data,subset=index)))

boot.fn(Auto,1:392)

set.seed(1)
boot.fn(Auto,sample(392,392,replace=T))
boot.fn(Auto,sample(392,392,replace=T))
    #ORDINARY NONPARAMETRIC BOOTSTRAP
    boot::boot(Auto,boot.fn,1000)
        #Est. SE(betahat_0)= 0.84
        #     SE(betahat_1)= 0.0073
summary(lm(mpg~horsepower,data=Auto))$coef

#now fitting the quadratic model which is supposed to have a better fit
boot.fn=function(data,
        index) coefficients(lm(mpg~horsepower+I(horsepower^2),
                               data=data,subset=index))
set.seed (1)
boot(Auto,boot.fn,1000)
    # Bootstrap Statistics :
    #     original          bias     std. error
    # t1* 56.900099702  0.035116401844 2.0300222526
    # t2* -0.466189630 -0.000708083404 0.0324241984
    # t3*  0.001230536  0.000002840324 0.0001172164
summary (lm(mpg~horsepower +I(horsepower ^2),data=Auto))$coef











