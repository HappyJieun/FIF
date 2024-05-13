
# set Repositories
setRepositories(ind = 1:7)

#library
library(C50) 
library(caret) #modleing
library(caTools)
library(data.table)
library(doParallel)
library(dplyr)
library(gganimate) #animated plot
library(ggplot2) #visualization
library(ggpubr) #visualization
library(gifski) #gif endcoding
library(glue) #handling of string
library(grid)
library(gridExtra)
library(httr)
library(janitor) #data cleansing
library(kernlab)
library(lubridate) #date, time
library(netstat)
library(plyr)
library(rJava)
library(rlang)
library(RSelenium)
library(rvest) #scraping
library(sda)
library(seleniumPipes)
library(stringr)
library(tibble)
library(tictoc)
library(tidyverse) #tibble
library(tidyr)
library(XML)
library(xml2)

## set work. dir
WORK_DIR <- "C:\\Users\\ABC\\Desktop"
DATA_DIR <- "C:\\Users\\ABC\\Desktop\\Data"
setwd(WORK_DIR)


#sets the system locale to "English"
Sys.setlocale("LC_ALL", "English")

### Step 1
## crawling
url <- "https://www.fifa.com/fifa-world-ranking/men?dateId=id13974"

remDr = remoteDriver(
  remoteServerAddr="localhost",
  port=4445L,
  browserName="chrome")

remDr$open()
remDr$navigate(url)

#로드까지 1초 대기
Sys.sleep(1)

#개인정보 수집 동의 버튼 클릭
privacy_button <- remDr$findElement(using = 'id', value = 'onetrust-accept-btn-handler')
privacy_button$clickElement()

#Date 추출
options <- remDr$findElements(using = 'css selector', value = '.ff-dropdown_dropupContentButton__WC4zi')
dropdown <- remDr$findElement(using = 'xpath', value = '/html/body/div[1]/div/div[2]/main/section[1]/div/div/div[1]/div[2]/div')
dropdown$clickElement()
num_options <- length(options)
num_options

texts <- lapply(options, function(opt) opt$getElementText())
texts

#새로고침후 1초 대기
remDr$navigate(url)
Sys.sleep(1)

## For parallel processing
cl <- makePSOCKcluster(6)
registerDoParallel(cl)

#첫번째 페이지 1:50
FIFARank50 <- data.frame()
for (i in 1:num_options) {
  tic()
  options <- remDr$findElements(using = 'css selector', value = '.ff-dropdown_dropupContentButton__WC4zi')
  dropdown <- remDr$findElement(using = 'xpath', value = '/html/body/div[1]/div/div[2]/main/section[1]/div/div/div[1]/div[2]/div')
  dropdown$clickElement()
  options[[i]]$clickElement()
  options[[i]]$clickElement()
  # 웹 페이지에서 class를 사용하여 테이블 가져오기
  table <- remDr$findElement(using = "class", value = "table_rankingTable__7gmVl")
  table_html <- table$getElementAttribute("outerHTML")[[1]]
  # html_node()와 html_table()을 이용하여 테이블 가져오기
  table_data <- read_html(table_html) %>% 
    html_node("table") %>%
    html_table(header = TRUE)%>% 
    select(-c(2,7,8)) %>% 
    mutate(Date = as.factor(texts[[i]]))
  
  FIFARank50 <- rbind(FIFARank50, table_data)
  print(i)
  toc()
  Sys.sleep(0.5)
}
dim(FIFARank50) # 16200*6

#새로고침후 1초 대기
remDr$navigate(url)
Sys.sleep(1)

# 두번째 페이지 51:90
dropdown <- remDr$findElement(using = 'xpath', value = '/html/body/div[1]/div/div[2]/main/section[1]/div/div/div[1]/div[2]/div')
options <- remDr$findElements(using = 'css selector', value = '.ff-dropdown_dropupContentButton__WC4zi')

FIFARank90 <- data.frame()
for (i in 1:num_options) {
  tic()
  remDr$executeScript("window.scrollTo(0, 200);")
  Sys.sleep(2)
  dropdown$clickElement()
  Sys.sleep(0.5)
  options[[i]]$clickElement()
  options[[i]]$clickElement()
  Sys.sleep(1)
  # 2번째 페이지
  dropdown2 <- remDr$findElement(using = 'xpath', value = '/html/body/div[1]/div/div[2]/main/section[2]/div/div/div[2]/div/div/div/div/div[2]/div[2]')
  dropdown2$clickElement()
  Sys.sleep(2)
  dropdown2$clickElement()
  Sys.sleep(1)
  # 웹 페이지에서 class를 사용하여 테이블 가져오기
  table <- remDr$findElement(using = "class", value = "table_rankingTable__7gmVl")
  table_html <- table$getElementAttribute("outerHTML")[[1]]
  Sys.sleep(0.5)
  # html_node()와 html_table()을 이용하여 테이블 가져오기
  table_data2 <- read_html(table_html) %>% 
    html_node("table") %>%
    html_table(header = TRUE)%>% 
    select(-c(2,7,8)) %>% 
    filter(RK <= 90) %>% 
    mutate(Date = as.factor(texts[[i]])) 
  
  FIFARank90 <- rbind(FIFARank90, table_data2)
  
  Sys.sleep(0.5)
  print(i)
  toc()
}
remDr$close()

## For stop parallel processing
stopCluster(cl)

# 변수 이름 바꾸기
dim(FIFARank50) # 16200*6
colnames(FIFARank50)
colnames(FIFARank50) <- c("RK", "Team", "Points", "Previous Points", "+/-", "Date")
dim(FIFARank90) # 12986*6
colnames(FIFARank90)
colnames(FIFARank90) <- c("RK", "Team", "Points", "Previous Points", "+/-", "Date")

## 두 페이지 데이터 합치기
FIFARank <- rbind(FIFARank50, FIFARank90) %>% 
  arrange(Date, RK) %>% 
  as_tibble()

# 324개의 날짜가 맞는지 확인
length(unique(FIFARank$Date))

## total data
dim(FIFARank)
glimpse(FIFARank)

## Step 2
# 상위 30위 안에 들었던 나라들
FIFARank_count <- FIFARank %>% 
  filter(RK <= 30) %>% 
  mutate(count = rep(1)) %>% 
  select(Team, count)
FIFARank_count <- aggregate(FIFARank_count$count, by=list(FIFARank_count$Team), FUN=sum)
colnames(FIFARank_count) <- c("Team", "count")
FIFARank_count %>% 
  arrange(-count)
# 나라 갯수 맞는지 확인
length(unique(FIFARank_count$Team))
length(FIFARank_count$Team)

# How many countries are there in total in the organized table
length(unique(FIFARank$Team))


## Step 3
FIFARank
## data 처리
FIFARank_formatted <- FIFARank %>% 
  select(RK, Team, Points, Date) %>% 
  filter(RK <= 20)

### plot 그리기
plot_base <- ggplot(FIFARank_formatted, aes(x = RK, y = Points, fill = Team)) + 
  geom_bar(stat = "identity", position = "dodge") + 
  ylim(0, 2000) + 
  theme_minimal() + 
  theme(legend.position = "none") +
  labs(title = "Top 20 FIFA Ranking", subtitle = "Date: {closest_state}", x = "Rank", y = "Points") +
  transition_states(Date, transition_length = 1, state_length = 1) +
  geom_text(aes(label = Team), vjust = -0.5, size = 1)

# Save as GIF
setwd(WORK_DIR)
anim_save("fifa_barplot.gif", plot_base, duration = 120, fps = 30)


##############################################################################
page <- httr::GET("https://www.fifa.com/fifa-world-ranking/men?dateId=id13974")
contents <- content(page, as = "text") 
ids <- regmatches(contents, (gregexpr("id\\d+", contents, perl = TRUE)))
ids <- unique(ids[[1]]) %>% as.character()
length(ids)

#date 뽑기
date_api <- regmatches(contents, gregexpr("\\d+\\s\\w+\\s\\d{4}", contents))
date_api <- unique(date_api[[1]]) %>% as.character()
length(date_api)

fifa_api <- data.frame()
for (i in 1:length(ids)){
  tic()

  page <- httr::GET(paste0("https://www.fifa.com/api/ranking-overview?locale=en&dateId=", ids[i]))
  
  contents <- content(page,"text")
  apiTable <- jsonlite::fromJSON(contents)$rankings$rankingItem %>%  
    as.data.frame() %>% 
    dplyr::select(rank, name, countryCode, totalPoints) %>% 
    filter(rank <= 90) %>% 
    mutate(Date = as.factor(date_api[i]))
  
  fifa_api <- rbind(fifa_api, apiTable) 
  
  print(i)
  toc()
}
fifa_api <- fifa_api %>% 
  as_tibble()
dim(fifa_api) # 29186 * 5
colnames(fifa_api) <- c("RK", "Country", "CountryCode", "Points", "Date")

# 나라이름과 code 합치기
fifa_api$Team <- paste(fifa_api$Country, fifa_api$CountryCode, sep = "")
fifa_api$Country <- NULL
fifa_api$CountryCode <- NULL
fifa_api <- fifa_api %>% 
  select(RK, Team, Points, Date)

## total data
dim(fifa_api)
glimpse(fifa_api)

## Step 2
# 상위 30위 안에 들었던 나라들
fifa_api_count <- fifa_api %>% 
  filter(RK <= 30) %>% 
  mutate(count = rep(1)) %>% 
  select(Team, count)
fifa_api_count <- aggregate(fifa_api_count$count, by=list(fifa_api_count$Team), FUN=sum)
colnames(fifa_api_count) <- c("Team", "count")
fifa_api_count %>% 
  arrange(-count)
# 나라 갯수 맞는지 확인
length(unique(fifa_api_count$Team))
length(fifa_api_count$Team)

# How many countries are there in total in the organized table
length(unique(fifa_api$Team))


## Step 3
fifa_api
## data 처리
fifa_api_formatted <- fifa_api %>% 
  select(RK, Team, Points, Date) %>% 
  filter(RK <= 20)

### plot 그리기
plot_base <- ggplot(fifa_api_formatted, aes(x = RK, y = Points, fill = Team)) + 
  geom_bar(stat = "identity", position = "dodge") + 
  ylim(0, 2000) + 
  theme_minimal() + 
  theme(legend.position = "none") +
  labs(title = "Top 20 FIFA Ranking", subtitle = "Date: {closest_state}", x = "Rank", y = "Points") +
  transition_states(Date, transition_length = 1, state_length = 1) +
  geom_text(aes(label = Team), vjust = -0.5, size = 1)

# Save as GIF
setwd(WORK_DIR)
anim_save("fifa_api_barplot.gif", plot_base, duration = 120, fps = 30)
