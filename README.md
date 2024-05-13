# FIFA 데이터 크롤링 및 분석


> Period: 2022.12 ~ 2023.02
> 
> Subject: Crawling


##### 23.02.15 last edit
---

## 0. Environment

+ Language : R

+ Editor : RStudio
---
## 1. Introduction

**Background**

국가들의 순위 변화를 분석하여 특정 전략이나 트렌드가 어떻게 경기 결과에 영향을 미치는 지 파악하고자 함.

---
## 2. Data Set

**Dataset Info.**

https://www.fifa.com/fifa-world-ranking/men?dateId=id13974


---
## 3. Summary

**(1) Data Preprocessing**

- 동적 사이트 수집을 위한 API, selenium 기법 적용
- 결측치 처리, variable selection 등 전처리 진행
- 상위 30위 국가 추출 및 시각화
  ![image](https://github.com/HappyJieun/FIF/assets/166107244/dda79c30-2da0-4005-9dac-16e40a5b08ca)

<br/>

**(2) Result**
- Cleaned data frame 생성
- Animated bar plot 생성
- 최다 우승 국가 경기 트렌드 파악

![barplot](https://github.com/HappyJieun/FIF/assets/166107244/80dd01b4-649f-4fa2-8a36-fdc48b6887ce)
