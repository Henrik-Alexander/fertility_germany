## 

library(eurostat)
library(stringr)
library(readr)
library(tidyverse)


## Graphic scheme -------------------------


theme_set(theme_bw(base_size = 12, base_family="serif"))



## Functions ------------------------------

search_data <- function(keyword, database=eurostat_births) {
  database[str_detect(database$title, pattern=keyword), ]
  }


## Eurostata ------------------------------


# Get the indicators
eurostat_births <- search_eurostat(pattern = "births")
eurostat_population <- search_eurostat(pattern = "population")

# Load the births
id_births <- "demo_fordagec"

# Load the exposures
id_pop <- res$code[res$title== "Population on 1 January by age group, sex and country of birth"]


# Load the age-specific fertility rate for the European Union
eu_births <- get_eurostat(id=id_births)
eu_pop <- get_eurostat(id=id_pop)

# Load the EU fertility rate
eu_fert <- readr::read_tsv(file="raw/estat_demo_frate.tsv")

# Load the US age-specific fertility rate
us_fert <- read.csv("raw/natality-dashboard.csv")

## Clean the data ========================

# Filter EU countries
eu_b <- eu_births[eu_births$geo=="EU27_2020", ]
eu_p <- eu_pop[eu_pop$geo=="EU27_2020", ]

# Estimate the rates
eu_b <- aggregate(values ~ age + geo + TIME_PERIOD, data=eu_b, FUN=sum)
eu_b <- eu_b %>% 
  filter(TIME_PERIOD=="2023-01-01") %>% 
  mutate(age_range = ifelse(str_detect(age, "-"), 1, 0),
         age_new = as.numeric(str_extract(age, "\\d+"))) %>% 
  filter(age_range==1)

# Estimate the exposures
eu_p <- aggregate(values ~ age + sex + geo + TIME_PERIOD, data=eu_p, FUN=sum)
eu_expos <- eu_p %>% 
  filter(TIME_PERIOD %in% paste0(c(2024, 2023), "-01-01") & sex=="F") %>% 
  group_by(age) %>% 
  reframe(exposure = 0.5 * values + 0.5 * lead(values)) %>% 
  filter(!is.na(exposure))


# Clean the US data
us_fert <- us_fert %>% 
  mutate(year = str_sub(Year.Quarter, 1, 4)) %>% 
  filter(Topic.Subgroup=="Age-specific Birth Rates" & Group == "All races and origins" & year==2024) %>% 
  group_by(Indicator) %>% 
  reframe(Rate = mean(Rate)/1000) %>% 
  mutate(age = paste0("Y", str_extract(Indicator, "\\d+(-\\d+)?"))) %>% 
  mutate(age = ifelse(age=="Y45", paste(age, 49, sep="-"), age))

# The data
asfr <- merge(eu_b, eu_expos, by=c("age"))

# Estimate the asfr
asfr$asfr <- with(asfr, values / exposure)

# Merge the data
rates <- merge(asfr, us_fert)

# Pivot longer
rates <- pivot_longer(rates, cols=c("Rate", "asfr")) %>% 
  mutate(geo=ifelse(name=="Rate", "US", geo))


### Compare the results -------------------

# Plot the age-specific rates
ggplot(rates, aes(x=age, y=value*1000, fill=geo)) +
  geom_col(position=position_dodge()) +
  geom_text(aes(label=round(value*1000, 1), y=value*1010), position=position_dodge(width=1), size=6)

# Make the counterfactual
rates %>% 
  group_by(geo) %>% 
  reframe(births = sum(value * exposure))

# Difference in the TFR
rates %>% 
  group_by(geo) %>% 
  reframe(tfr = sum(value * 5))

### END ###################################