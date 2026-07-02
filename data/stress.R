# stress data

stress <- read.csv("https://uoepsy.github.io/data/stressweek_nested.csv")
stress$stress <- stress$stress + 6
stress$day <- stress$day - 1
saveRDS(stress, "data/stress.rds")
