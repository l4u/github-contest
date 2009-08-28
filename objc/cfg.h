
//
// config, because I'm lazy
//


// model building
#define KNN_STORE 				10
#define KNN_READ 				10


// candidate selection
#define TOP_RANKED_REPOS 		100
// num top n we print (basis for insights!)
#define TOP_RANKED_REPOS_PRINT 	20

// predictions
#define MAX_REPOS 				10

// predictions
#define USE_EXT_CLASSIFIER 		false
// limited test user processing for testing
#define TASTE_TEST 				true
// alternative indicator strategy using ranks (it sucks!)
#define USE_RANK_INDICATORS 	false

// training data for external classifier
#define GENERATE_TRAINING_DATA 	false
#define NUM_TRAINING_USERS 		100