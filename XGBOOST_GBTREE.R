#Author @ Mohammed 26/01/2017

#Load Libraries
source("Libraries.R")

data<-read.csv("FINALE_MOD_DATA_WITHOUT_NA.csv",header = T)
data<-data[,-1]
data<-data[,-5]

ndata<-data
View(head(ndata))
#======================================================================
#XGBOOST
#======================================================================
train_test<-ndata
features = names(train_test)
for (f in features) {
  if (class(train_test[[f]])=="factor") {
    levels <- unique(train_test[[f]])
    train_test[[f]] <- as.numeric(as.integer(factor(train_test[[f]], levels=levels)))
  }
}

for(i in 1:32561){
  if(train_test[i,14]==1)
  {
    train_test[i,14]=0
  }
  else if(train_test[i,14]==2)
  {
    train_test[i,14]=1
  }
}

set.seed(999)
splitIndex<-createDataPartition(train_test$income,p=.70,list=F,times=1)
train<-train_test[splitIndex,]
test<-train_test[-splitIndex,]
training_data<-train
testing_data<-test
#====================================================================
######################## Preparing for xgboost

dtrain = xgb.DMatrix(as.matrix(training_data[,-14]), 
                     label=training_data[,14])
dtest = xgb.DMatrix(as.matrix(testing_data[,-14]))

xgb_param_adult = list(
  nrounds = c(700),
  eta = 0.075,#eta between(0.01-0.2)
  max_depth = 6, #values between(3-10)
  subsample = 0.7,#values between(0.5-1)
  colsample_bytree = 0.7,#values between(0.5-1)
  num_parallel_tree=1,
  objective='binary:logistic',
  booster='gbtree',
  min_child_weight = 1,
  eval_metric="auc"
)

res = xgb.cv(xgb_param_adult,
             dtrain,
             nrounds=700,   # changed
             nfold=100,           # changed
             early_stopping_rounds=50,
             print_every_n = 10,
             verbose= 1)



xgb.fit = xgb.train(xgb_param_adult, dtrain, 500)

#===========================AUC
auc<-roc(testing_data[,14],predict(xgb.fit,dtest))
print(auc)
plot(roc(test$income,predict(xgb.fit,dtest)),print.auc=T)


# Confusion Matrix
preds <- ifelse(predict(xgb.fit, newdata=as.matrix(testing_data[,-14])) >= 0.48, 1, 0)
caret::confusionMatrix(testing_data[,14], preds, mode = "prec_recall")

#========87.02% accuracy
