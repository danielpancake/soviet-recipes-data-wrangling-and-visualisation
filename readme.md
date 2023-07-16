# unnamed data wrangling yadda yadda project

## Project Description

1. Data Scraping
    1. Target websites
        - [Main source for Soviet recipes](https://sov-obshchepit.ru/)
        - Not used yet:
            - [Website "1000.menu"](https://1000.menu/catalog/recepty-sovetskix-vremen)
            - [Website "webspoon"](https://webspoon.ru/cuisine/kuhnja-sssr)
            - [Website "povarenok"](https://www.povarenok.ru/recipes/kitchen/101/?sort=date_create_asc&order=desc)
    2. Raw data format
        At first, I found it hard to implement a nested json structure, so I decided to use a flat structure for the raw data instead. The structure is as follows:

        ```json
        {
            "category": "category",
            "subcategory": "subcategory",
            "recipe_name": "recipe_name",
            "ingredients": [
                "ingredient_1", "ingredient_2", "ingredient_3"
                // ^ it's really a combination of ingredient and its quantity
            ],
        }
        ```

        To scrape raw data, run:

        ```bash
        cd ./scrapping
        scrapy crawl sov-obshchepit -O ../data/raw_data.json
        ```

    3. Nested raw data format

        Eventually, I figured out a way to implement a nested json structure. I store scrapped data in a nested json structure (`nested_index` in `sov_obshchepit.py`) and write it to a json file when the spider is closed. The structure of this file is as follows:

        ```json
        {
            "category_name": {
                "subcategory_name": {
                    "recipe_name": {
                        "ingredients": [
                            "ingredient_1", "ingredient_2", "ingredient_3"
                            // ^ it's really a combination of ingredient and its quantity
                        ],
                    }
                }
            } 
        }
        ```

        To scrape raw data with nested structure, run:

        ```bash
        cd ./scrapping
        scrapy crawl sov-obshchepit -a nested_output=../data/raw_nested_data.json
        ```

    4. Sorted and prettified raw data format

        You migth want to sort the raw data by category, subcategory, and recipe name. To do so, run:

        ```bash
        cat ./data/raw_data.json | jq 'sort_by(.category, .subcategory, .recipe_name)' > ./data/raw_data_sorted.json
        ```

2. Data Wrangling

    Part of the data cleaning process is done during the scraping process. For example, all trailing whitespaces are removed from the scraped data, as well as any empty strings or invisible characters. The rest of the data cleaning is done in the `data_wrangling.ipynb` notebook.

3. Data Analysis

    pass

4. Data Visualization

    pass

## Misc

Visual inspiration: [Soviet drawn images](https://trip-for-the-soul.ru/foto/chto-gotovili-v-sssr-na-kazhdyj-den.html)
