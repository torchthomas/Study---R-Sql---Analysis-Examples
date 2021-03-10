# Subset selection methods
# we predict the salary of baseball players based on the performance of their previous year
#.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Clear vars/mem,set notation and other limits
rm(list=ls()); gc();options(digits=7)
options(scipen=999) # turn off scientific notation

# Make functions to read in all needed packages 
readInPackages=function(packages){
    #for reading in packages
    packsInstalling <- packages[!packages %in% installed.packages()]
    for(lib in packsInstalling) install.packages(lib,dependencies=TRUE)
    sapply(packages,require,character=TRUE)
}
# Load packages       
packages <- c(
 "stats",#for contrasts fn
 "ISLR",#for data Smarket(i.e.,stock market)
 "leaps",#for the regsubsets function
 "pls",#for PLS
 "boot",#for bootstrapping
 "glmnet",#for ridge/lasso regression
 "MASS"#,#for lda,qda
)
readInPackages(packages)
#.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(ISLR); fix(Hitters)
names(Hitters)
    # dim(Hitters) # dim: 322 x 20
    # sum(is.na(Hitters$Salary)) # 59 NAs
#remove the NAs 322-59 rows
Hitters=na.omit(Hitters)# dim: 263 x 20

regfit.full=leaps::regsubsets(Salary~.,Hitters)
summary(regfit.full)

#control how many vars with nvmax
regfit.full=leaps::regsubsets(Salary~.,Hitters,nvmax=19)
reg.summary=summary(regfit.full)
names(reg.summary)

#looking at the residual sum of squares,RSS as we increase the 
    #number of variables in the subsets procedure
    par(mfrow=c(2,2))
    plot(reg.summary$rss,xlab="Number of Variables",ylab="RSS",
           type="l")
    plot(reg.summary$adjr2,xlab="Number of Variables",
           ylab="Adjusted RSq",type="l")
    
    #find the num of vars with highest RSS
    points(11,reg.summary$adjr2[which.max(reg.summary$adjr2)],
           col="red",cex=2,pch=20)
    
    #find low Mallow's C_p statistic(for ols it's equiv to AIC),plot it
    plot(reg.summary$cp,xlab="Number of Variables",ylab="Mallow's Cp",
         type='l')
        points(10,reg.summary$cp[which.min(reg.summary$cp)],
               col="red",cex=2,pch=20)
    
    #find the BIC,plot it; i.e. optimal number of parameters to maximize likelihood
    plot(reg.summary$bic,xlab="Number of Variables",ylab="BIC",
           type='l')
        points(6,reg.summary$bic[which.min(reg.summary$bic)],
               col="red",cex=2,pch=20)
    #end plots
    dev.off()
    plot(regfit.full,scale="r2")
    plot(regfit.full,scale="adjr2")
    plot(regfit.full,scale="Cp")
    plot(regfit.full,scale="bic")

#.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#FORWARD AND BACKWARD STEPWISE SELECTION
#models differ significantly after including the 7th variable models,before that
    #they're quite similar,full subset model is best still
regfit.fwd=leaps::regsubsets(Salary~.,data=Hitters,nvmax=19,method="forward")
    summary(regfit.fwd)
regfit.bwd=leaps::regsubsets(Salary~.,data=Hitters,nvmax=19,method="backward")
    summary(regfit.bwd)
    coef(regfit.full,7)
    coef(regfit.fwd,7)
    coef(regfit.bwd,7)
 
#.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#model selection with validation set and cross validation approach
set.seed(1);
#first my a sample validation set
train=sample(c(TRUE,FALSE),nrow(Hitters),rep=TRUE)
test=(!train)

#look at best subset reg
regfit.best=leaps::regsubsets(Salary~.,data=Hitters[train,],nvmax=19)

#validation set error
test.mat=model.matrix(Salary~.,data=Hitters[test,])

(val.errors=rep(NA,19))
for(i in 1:19){
    coefi=coef(regfit.best,id=i)
    pred=test.mat[,names(coefi)]%*% coefi
    val.errors[i]=mean((Hitters$Salary[test]-pred)^2)
}; val.errors
#select min error model
coef(regfit.best,which.min(val.errors))

#no nice predict() for regsubsets exists,so make one  to get the formula call
    #output the model matrix,and grab the coefficients wit htheir name,and then 
    # predict the model
predict.regsubsets=function(object,newdata,id,...){
    form=as.formula(object$call[[2]])
    mat=model.matrix(form,newdata)
    coefi=coef(object,id=id)
    xvars=names(coefi)
    mat[,xvars]%*% coefi
}

regfit.best=leaps::regsubsets(Salary~.,data=Hitters,nvmax=19)
coef(regfit.best,10)
    #note: the 10-var model from training is different than the 10-var model on the test

#CROSS-VALIDATION portion next
    #choose 10 sets,sample data for each from full data,init'l cross-valid'n err.s  
    k=10
    set.seed(1)
    folds=sample(1:k,nrow(Hitters),replace=TRUE)
    cv.errors=matrix(NA,k,19,dimnames=list(NULL,paste(1:19)))

    #Next,predict the model for each class(for whom we select best model each)
    for(j in 1:k){
        best.fit=regsubsets(Salary~.,data=Hitters[folds !=j,],nvmax=19)
        for(i in 1:19) {
        pred=predict(best.fit,Hitters[folds==j,],id=i)
        cv.errors[j,i]=mean((Hitters$Salary[folds==j]-pred)^2)
        }
    }
    
    mean.cv.errors=apply(cv.errors,2,mean); mean.cv.errors
    #plot errors
    par(mfrow=c(1,1))
    plot(mean.cv.errors,type='b')
    dev.off()
    
    #cross-valid'ns selects 11 var model
    reg.best=regsubsets(Salary~.,data=Hitters,nvmax=19)
    coef(reg.best,11)
#.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#RIDGE REG,LASSO REG
#ensure NAs are gone
x=model.matrix(Salary~.,Hitters)[,-1]
y=Hitters$Salary

#RECALL: 1. penalty term alpha dictates ridge/lasso regression
#        2. glmnet standardizes terms
#ridge,when alpha=0
library(glmnet)
#create a grid to later plot values over
    grid=10^seq(10,-2,length=100)
    ridge.mod=glmnet::glmnet(x,y,alpha=0,lambda=grid)

    #comparing L2 norms
    ridge.mod$lambda[50];coef(ridge.mod)[,50]#lambda=11498
    ridge.mod$lambda[60];coef(ridge.mod)[,60]#lambda=705
    
    sqrt(sum(coef(ridge.mod)[-1,50]^2))#lambda=11498
    sqrt(sum(coef(ridge.mod)[-1,60]^2))#lambda=705
    
    #predict coefs for some lambda,e.g. lambda=45
    stats::predict(ridge.mod,s=45,type="coefficients")[1:20,]
    
  #TEST ERROR estimation
    #split samples for training/testing
    set.seed(1)
    train=sample(1: nrow(x),nrow(x)/2)
    test=(-train)
    y.test=y[test]
    ridge.mod=glmnet(x[train,],y[train],alpha=0,lambda=grid,thresh=1e-12)
    ridge.pred=predict.glmnet(ridge.mod,s=4,newx=x[test,])
    
    #TEST MSE,lambda=4; will move to choose lambda optimally and not by simple
        #guessing see bestlam for outcome
    mean((ridge.pred -y.test)^2)
    mean((mean(y[train ])-y.test)^2)
    ridge.pred=predict.glmnet(ridge.mod,s=1e10,newx=x[test,])
    mean((ridge.pred -y.test)^2)
    
    ridge.pred=predict.glmnet(ridge.mod,s=0,newx=x[test,],exact=T,x=as.matrix(x[train,]),y=y[train])
    mean((ridge.pred -y.test)^2)
    lm(y~x,subset=train)
    predict.glmnet(ridge.mod,s=0,exact=T,type="coefficients",x=as.matrix(x[train,]),y=y[train])[1:20,]
    

    
    #optimal lambda,bestlam
    set.seed(1)
    cv.out=glmnet::cv.glmnet(x[train,],y[train],alpha=0)
    plot(cv.out)
    bestlam=cv.out$lambda.min
    bestlam
    
    ridge.pred=predict(glmnet::glmnet(x[train,],y[train],alpha=0,lambda=grid,thresh=1e-12),s=bestlam,newx=x[test,])
    mean((ridge.pred -y.test)^2)
    
    out=glmnet(x,y,alpha=0)
    predict(out,type="coefficients",s=bestlam)[1:20,]
    
#LASSO,when alpha=1
lasso.mod=glmnet(x[train,],y[train],alpha=1,lambda=grid)
    plot(lasso.mod)
    
    set.seed(1)
    cv.out=cv.glmnet(x[train,],y[train],alpha=1)
    plot(cv.out)
       (bestlam=cv.out$lambda.min)
    lasso.pred=predict(lasso.mod,s=bestlam,newx=x[test,])
        mean((lasso.pred -y.test)^2)
    out=glmnet(x,y,alpha=1,lambda=grid)
       (lasso.coef=predict(out,type="coefficients",s=bestlam)[1:20,])
    



#.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#PRINCIPAL COMPONENTS REGRESSION :=PCR; PARTIAL LEAST SQUARES := PLS
    #PCR
    library(pls)
    set.seed(2)
    (pcr.fit=pls::pcr(Salary~.,
                     data=Hitters,
                     scale=TRUE,#standardize
                     validation="CV"#activates 10-fold cross-validation
                    ))
    set.seed(1)
    pcr.fit=pcr(Salary~.,data=Hitters,subset=train,scale=TRUE,
             validation="CV")
    #look at the validation plots to see how the model looks with the R^2 and the 
        #mean squared error prediction(MSEP)
    validationplot(pcr.fit,val.type="MSEP"); validationplot(pcr.fit,val.type="R2")
    
    #n=7 components explains 92% of variation
    pcr.pred=predict(pcr.fit,x[test,],
                      ncomp=7 #n=7
                     )
    mean((pcr.pred -y.test)^2)
    
    #Looking at the variation explained as we add more components to the PCR
    pcr.fit=pcr(y~x,scale=TRUE,ncomp=7)
    summary(pcr.fit)
    
    #PLS
    #The goal is to explain the variance in the error beyond the simple cross-validation analysis itself
    set.seed(1)
    pls.fit=plsr(Salary~.,data=Hitters,subset=train,scale=TRUE,
       validation="CV")
    summary(pls.fit)
    validationplot(pls.fit,val.type="MSEP")
    validationplot(pls.fit,val.type="R2")
    
    #LOWEST CV err
        #when n=2
        pls.pred=predict(pls.fit,x[test,],ncomp=2 # n=2
                         );mean((pls.pred -y.test)^2)
    
    #full data 
    pls.fit=plsr(Salary~.,data=Hitters,scale=TRUE,ncomp=2)
    summary(pls.fit) #45.40% of all explained with n=2
    
print("Comparatively,PCR with 7 components is about as good as PLS with 2 components.")
    

#####
#Bonus FizzBuzz
# fnn=function(x){
#            if(is.null(x) || is.na(x)) stop("Not an integer message")
#            else if((x%%3>0) &(x%%5>0)) print(as.integer(x))
#            else {
#                if(x%%3==0 & !(x%%5==0)) ret="Fizz"
#                if(x%%5==0 & !(x%%3==0)) ret="Buzz"
#                else{
#                    ret="FizzBuzz"
#                }
#            }
#        }
# sapply(STDIN,fnn)
    