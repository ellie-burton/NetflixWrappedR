# **Netflix Viewing Habits Analyzer**

This R project analyzes personal Netflix viewing history to uncover viewing patterns, calculate total watch time, and statistically determine if "binge-watching" behavior varies by day of the week.

## **📋 Prerequisites**

To run this analysis, you need:

1. **R** and **RStudio** installed on your computer.  
2. The following R packages (the script will attempt to install them if missing):  
   * tidyverse (Data manipulation and plotting)  
   * lubridate (Date/Time handling)  
   * ggpubr (Q-Q Plots)

## **📥 Step 1: Get Your Netflix Data**

1. Log in to your Netflix account.  
2. Go to **Account** \> **Download your personal information**.  
3. Request the data. Netflix will email you a link (this can take 24-48 hours, though often it's faster).  
4. Download the zip file provided by Netflix.  
5. Extract the zip file and locate ViewingActivity.csv inside the Content\_Interaction folder (folder names may vary slightly).

## **⚙️ Step 2: Project Setup**

1. Download the netflix\_project\_complete.R script from this repository.  
2. Create a new folder on your computer for this analysis.  
3. Place **both** the R script and your ViewingActivity.csv file into this folder.  
   * *Note:* The CSV file **must** be named ViewingActivity.csv. If yours is named differently, rename it or update line 25 in the script.

## **🚀 Step 3: Running the Analysis**

1. Open netflix\_project\_complete.R in RStudio.  
2. **Important:** Ensure your "Working Directory" is set to the folder where your files are located.  
   * *In RStudio: Session \-\> Set Working Directory \-\> To Source File Location*.  
3. Run the entire script (Ctrl+A to select all, then Ctrl+Enter to run).

## **📊 Output**

The script will output the following in the R Console and Plots pane:

### **Console Statistics:**

* **Total Watch Time:** Total hours and days of your life spent on Netflix.  
* **Top 5 Shows:** Your most-watched series by duration.  
* **TV vs. Movie Ratio:** Percentage breakdown of content type.  
* **Most Active Day:** The single date with the highest viewing time.  
* **Statistical Tests:** Results for Normality (Shapiro-Wilk), Variance (Levene’s), and Significance (Kruskal-Wallis).

### **Visualizations:**

1. **Timeline Line Plot:** Daily usage trends over the lifespan of the data.  
2. **Boxplot:** Viewing intensity distribution by Day of the Week.  
3. **Density Plot:** Distribution curves showing skewness (now formatted in a 4x3 grid).  
4. **Q-Q Plot:** Visual check for normality.  
5. **Heatmap (Average Intensity):** A visual grid showing your "Active Day" viewing habits (Day of Week vs. Hour of Day).

## **📝 Methodology Note**

This tool calculates "Intensity on Active Days." It filters out days where 0 minutes were watched to prevent skewing the data. It answers the question: *"When I decide to watch Netflix, how long do I watch for?"* rather than *"How often do I watch Netflix?"*
