# Classification QDA, LDA, Logistic (GLM), KNN
#. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Make functions to read in all needed packages 
readInPackages = function(packages){
    #for reading in packages
    packsInstalling <- packages[!packages %in% installed.packages()]
    for(lib in packsInstalling) install.packages(lib, dependencies = TRUE)
    sapply(packages, require, character=TRUE)
}
# Load packages       
packages <- c(
    "stats",#for contrasts fn
    "ISLR", #for data Smarket (i.e., stock market)
    "class",#for knn()
    "MASS"#,#for lda, qda
)
readInPackages(packages)

#Library for data and stats functions
library(ISLR);library(stats)
#Summary of data (stock market)
str(Smarket)
dim(Smarket)
summary(Smarket)
pairs(Smarket)

#looking at the correlation which drives cov matrix (helps identify which alg is best)
#col 9 non-numeric
cor(Smarket)[,-9]

#Notice corr'n betwen lags (intuitive), shares traded increase over time ('01--'05)
attach (Smarket)
plot(Volume)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Logistic
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
glm.fit=glm(Direction~Lag1+Lag2+Lag3+Lag4+Lag5+Volume ,
            data=Smarket ,family =binomial)
#no evidence supporting a significant relation betwn lag and Direction
summary(glm.fit)

#check coefs, summary about estimate, std. err., z-val, and P(>|z|)
coef(glm.fit)
summary(glm.fit)$coef
summary(glm.fit)$coef[,4]

#summarily, we can use the predict function to predict the probability an event occurs
    #here, the event that the market goes up (if only)
glm.probs =predict(glm.fit ,type ="response")
glm.probs[1:10]

#check dummy for up or down
stats::contrasts(Direction)

#continuing prediction
glm.pred=rep("Down" ,1250)
glm.pred[glm.probs >.5]="Up"

#let's check the confusion matrix since much of the analysis depends on 
    #what the correlation matrix shows, as it relies heavily on the gaussian assumption and
    #NOTE: diagonal elements communicate a correct prediction while the 
    #      off-diagonal elements show incorrect predictions
    #      which means we correctly predicted 507 days (up) and 145 days (down)
table(glm.pred,Direction)
#The training error rate is 100*(1-.5216)= 47.84%
    #what's missing here is that what matters is the obvious prediction power of the model on data it didn't train on
mean(glm.pred==Direction) #should be .5216
#KEY
    #vector of obns between 2001--2004
    train<- (Year<2005)
    Smarket.2005<-Smarket[!train,]; #dim 252 x 9
    Direction.2005 <- Smarket$Direction[!train]

#Let's look at what it's like when we predict on data we have not trained on
glm.fit=glm(Direction~Lag1+Lag2+Lag3+Lag4+Lag5+Volume ,
            data=Smarket ,family=binomial ,subset =train )
glm.probs =predict(glm.fit, Smarket.2005, type="response")

glm.pred=rep("Down",252)
glm.pred[glm.probs >.5]="Up"
table(glm.pred ,Direction.2005)
Direction.2005
# set error rate is then (1-.48)*100 = 52%
mean(glm.pred== Direction.2005)#.48

#regularizing our model here reduces the variance since insignificant predictors/covariates
    #only serve to increase the variance of our model
    # Thus, we return the logistic with the greatest predictive power
    # wherein 56% of the daily movements are correctly predicted
    # oddly enough, on days when the model is correct, it has a pred. rate of 58%
glm.fit=glm(Direction~Lag1+Lag2 ,data=Smarket ,family =binomial ,
            subset =train)
glm.probs =predict(glm.fit ,Smarket.2005 , type="response")
glm.pred=rep("Down" ,252)
glm.pred[glm.probs >.5]="Up"
table(glm.pred ,Direction.2005)

mean(glm.pred== Direction.2005) # here is the .56 --> 56%
#clearly,
106/(106+76) #=.582, hence, 58%

#counterfactual, spse given lag1, lag2 pair, wherein it's 
predict(glm.fit ,
         newdata =data.frame(Lag1=c(1.2,1.5) ,
                             Lag2=c(1.1,-0.8)),
         type ="response")
    #.4791      .4961      #(for 1, 2 respectively) 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#LDA
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(MASS) #for lda function

lda.fit=MASS::lda(Direction~Lag1+Lag2,
                  data=Smarket#,subset=train
                  )
lda.fit #what's not shown is the group means
    # Prior probabilities of groups :
    # Down Up
    # 0.492 0.508

#to visualize, we find a cyclical pattern/trend for subsequent pos/neg days to be neg/pos respectively 
plot(lda.fit)

#the linear discriminants
lda.pred=predict(lda.fit,Smarket.2005)
names(lda.pred)

#notice almost identical predictions between lda and logistic
lda.class =lda.pred$class
table(lda.class ,Direction.2005) 
mean(lda.class == Direction.2005) #.56

#when a 50% threshold is applied to the posterior probabilities
sum(lda.pred$posterior[ ,1] >=.5) # 70 days
sum(lda.pred$posterior[,1]<.5)    # 182 days

# posterior probability is associated with a market decrease
lda.pred$posterior[1:20 ,1]
lda.class[1:20]

#counterfactual, spse threshold is different: with post. prob. 90%
sum(lda.pred$posterior[,1]>.9) # 0 days meet this threshold
    #NOTE; greatest post. prob. decrease in all of 2005 was 52.02%
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#QDA
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Assumption: QDA assumes that each class k has its own covariance matrix
            # since lda estimates more classifiers since its linear in x, rather,
            # so k*p linear coeffs to estimate (can suffer from high bias)
qda.fit=MASS::qda(Direction~Lag1+Lag2 ,data=Smarket ,subset =train)
qda.fit #what's not shown is the group means
    # Prior probabilities of groups :
    # Down Up
    # 0.492 0.508

#predictions, like the fns in LDA
qda.class = predict(qda.fit ,Smarket.2005)$class
table(qda.class,Direction.2005)

#look at the accuracy, just as we'd suspect since QDA suffers from
mean(qda.class == Direction.2005) # .599 #woah!!! Nearly 60% accuracy

#Note: it's recommended to decide between models ONLY AFTER you test all on a larger data set 

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#K-Nearest Neighbors (knn, k-nn)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(class) # for fn knn(), demands four inputs, for nonparametric applications esp. 
    #four inputs: (following notation from Gareth et al 2014)
            #1. [matrix] of covariates related to/from the training data,
            #2. [matrix] of covariates related to/from the test data
            #3. <v> := vector of training obn.s
            #4. K:= set number of classes/neighbors
    #knn is black-box-ish insofar as we don't deduce the powerful predictors
#read libs; set seed
library (class); set.seed(1)
#defining the two matrices and the vector of training obn.s  [1--3]()
    # and 4, the classes/neighbors
train.X<-cbind(Lag1 ,Lag2)[train,]#1
test.X<-cbind(Lag1 ,Lag2)[!train,]#2
train.Direction <-Direction[train]#3
k<-1                              #4

#k-nn-1 or knn-1, one neighbor
knn.pred=knn (train.X,
              test.X,
              train.Direction,
              k=k)
table(knn.pred, Direction.2005)
    #error rate
    (83+43) /252 #.5 

#3 neighbors (and k>3 has no improvements)
k<-3
knn.pred=class::knn(train.X,
                    test.X,
                    train.Direction,
                    k=3)
table(knn.pred, Direction.2005)
    #error rate now
    mean(knn.pred== Direction.2005) #.536 !

#########################
#Summary: QDA > LDA > knn w/ k=3 > knn w/ k=1. QDA has the best results out of all the models with near 60% test accuracy