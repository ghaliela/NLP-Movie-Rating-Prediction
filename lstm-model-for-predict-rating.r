{"metadata":{"kernelspec":{"name":"ir","display_name":"R","language":"R"},"language_info":{"name":"R","codemirror_mode":"r","pygments_lexer":"r","mimetype":"text/x-r-source","file_extension":".r","version":"4.0.5"}},"nbformat_minor":4,"nbformat":4,"cells":[{"source":"<a href=\"https://www.kaggle.com/ghaliela/lstm-model-for-predict-rating?scriptVersionId=86587682\" target=\"_blank\"><img align=\"left\" alt=\"Kaggle\" title=\"Open in Kaggle\" src=\"https://kaggle.com/static/images/open-in-kaggle.svg\"></a>","metadata":{},"cell_type":"markdown","outputs":[],"execution_count":0},{"cell_type":"code","source":"# This R environment comes with many helpful analytics packages installed\n# It is defined by the kaggle/rstats Docker image: https://github.com/kaggle/docker-rstats\n# For example, here's a helpful package to load\n\nlibrary(tidyverse) # metapackage of all tidyverse packages\n\n# Input data files are available in the read-only \"../input/\" directory\n# For example, running this (by clicking run or pressing Shift+Enter) will list all files under the input directory\n\nmovies <- read.csv(\"../input/tmdb-movie-metadata/tmdb_5000_movies.csv\")\n\n\n# You can write up to 20GB to the current directory (/kaggle/working/) that gets preserved as output when you create a version using \"Save & Run All\" \n# You can also write temporary files to /kaggle/temp/, but they won't be saved outside of the current session","metadata":{"_uuid":"051d70d956493feee0c6d64651c6a088724dca2a","_execution_state":"idle","execution":{"iopub.status.busy":"2022-01-30T22:35:56.381552Z","iopub.execute_input":"2022-01-30T22:35:56.416307Z","iopub.status.idle":"2022-01-30T22:35:57.509149Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"library(keras)\nlibrary(tensorflow)\nlibrary(tm)\nlibrary(spacyr)\nlibrary(utf8)\nlibrary(tidyverse)\n# choose columns of interest\ndata <- movies %>% select(overview, vote_average)\nplots <- data[,1]\nratings <- data[,2]\n\n# check if everything is unicoded\nplots[!utf8_valid(plots)]\n\n# check if text is normalized\nplots_NFC <- utf8_normalize(plots)\nsum(plots_NFC != plots)\n\n# remove punctuation\nplots <- gsub('[[:punct:] ]+',' ',plots)\n\ndata$overview <- plots\n\nplots[1]\n","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:35:57.512459Z","iopub.execute_input":"2022-01-30T22:35:57.513782Z","iopub.status.idle":"2022-01-30T22:35:59.03886Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"corpus = VCorpus(VectorSource(data$overview))\n#Checking the first movie review before Data Cleaning\nas.character(corpus[[1]])\n\ncorpus = tm_map(corpus, content_transformer(tolower))\ncorpus = tm_map(corpus, removeNumbers)\ncorpus = tm_map(corpus, removePunctuation)\ncorpus = tm_map(corpus, removeWords, stopwords(\"english\"))\ncorpus = tm_map(corpus, stemDocument)\ncorpus = tm_map(corpus, stripWhitespace)\nas.character(corpus[[1]])","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:35:59.041817Z","iopub.execute_input":"2022-01-30T22:35:59.043075Z","iopub.status.idle":"2022-01-30T22:36:02.288043Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"# perform a DTM for term frequency (Data used in the model)\ndtm = DocumentTermMatrix(corpus)\ndtm\ndim(dtm)","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:36:02.291265Z","iopub.execute_input":"2022-01-30T22:36:02.292659Z","iopub.status.idle":"2022-01-30T22:36:03.160434Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"dataset = as.data.frame(as.matrix(dtm))\n\nhead(dataset)\ndim(dataset)\n\ndataset$Class = ratings\n\n# split training and test data\nset.seed(222)\nsplit = sample(2,nrow(dataset),prob = c(0.75,0.25),replace = TRUE)\ntrain_set = dataset[split == 1,]\ntest_set = dataset[split == 2,] \n","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:36:03.163574Z","iopub.execute_input":"2022-01-30T22:36:03.164849Z","iopub.status.idle":"2022-01-30T22:36:09.146258Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"# tune model lstm\nmodel <- keras_model_sequential()\nmodel %>%\n  # Creates dense embedding layer; outputs 3D tensor\n  # with shape (batch_size, sequence_length, output_dim)\n  layer_embedding(input_dim = 2000,\n                  output_dim = 128,\n                  input_length = 1000) %>%\n  bidirectional(layer_lstm(units = 64)) %>%\n  layer_dropout(rate = 0.1) %>%\n  layer_dense(units = 1)\n","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:36:09.149591Z","iopub.execute_input":"2022-01-30T22:36:09.150943Z","iopub.status.idle":"2022-01-30T22:36:18.26963Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"# choose model metrics and loss function\nmodel %>% compile(\n  loss = 'mean_squared_error',\n  optimizer = 'adam',\n  metrics = c('cosine_similarity')\n)","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:36:18.273289Z","iopub.execute_input":"2022-01-30T22:36:18.274722Z","iopub.status.idle":"2022-01-30T22:36:18.300234Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"# Train model\ncat('Train...\\n')\n\ntrain_X <- train_set %>% select(-Class)\ntest_X <- test_set %>% select(-Class)\n\nmodel %>% fit(\n  train_X, train_set$Class,\n  batch_size = 100,\n  epochs = 5,\n  validation_data = list(test_X, test_set$Class)\n)","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:36:18.303457Z","iopub.execute_input":"2022-01-30T22:36:18.304835Z","iopub.status.idle":"2022-01-30T22:46:53.4261Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"# predict on test data\ntext.pred <- predict(model, test_X)","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:46:53.429429Z","iopub.execute_input":"2022-01-30T22:46:53.430808Z","iopub.status.idle":"2022-01-30T22:50:27.184723Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"model","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:50:27.18808Z","iopub.execute_input":"2022-01-30T22:50:27.189467Z","iopub.status.idle":"2022-01-30T22:50:27.208957Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"# model overall mean squared error\nmean((text.pred-test_set$Class)^2)","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:50:27.211996Z","iopub.execute_input":"2022-01-30T22:50:27.213464Z","iopub.status.idle":"2022-01-30T22:50:27.229857Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"# test model on new text\ntest_plot <- \"A terrible movie as everyone has said. What made me laugh was the cameo appearance by Scott McNealy\"\ntest_corpus = VCorpus(VectorSource(test_plot))\n#Checking the first movie review before Data Cleaning\nas.character(test_corpus[[1]])\n\n#corpus = tm_map(corpus, content_transformer(tolower))\ntest_corpus = tm_map(test_corpus, removeNumbers)\ntest_corpus = tm_map(test_corpus, removePunctuation)\ntest_corpus = tm_map(test_corpus, removeWords, stopwords(\"english\"))\ntest_corpus = tm_map(test_corpus, stemDocument)\ntest_corpus = tm_map(test_corpus, stripWhitespace)\n\ntest_dtm = DocumentTermMatrix(test_corpus)\n\ntest_dataset = as.data.frame(as.matrix(test_dtm))\ntest_dataset\n","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:50:27.2329Z","iopub.execute_input":"2022-01-30T22:50:27.234259Z","iopub.status.idle":"2022-01-30T22:50:27.275943Z"},"trusted":true},"execution_count":null,"outputs":[]},{"cell_type":"code","source":"# new plot score\npredict(model, test_dataset)","metadata":{"execution":{"iopub.status.busy":"2022-01-30T22:50:27.278807Z","iopub.execute_input":"2022-01-30T22:50:27.280057Z","iopub.status.idle":"2022-01-30T22:50:27.795992Z"},"trusted":true},"execution_count":null,"outputs":[]}]}