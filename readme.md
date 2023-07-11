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
        I found it hard to implement a nested json structure immediately at the scraping stage, so I decided to use a flat structure for the raw data. The structure is as follows:

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

2. Data Wrangling

    pass

3. Data Analysis

    pass

4. Data Visualization

    pass

## Misc

Visual inspiration: [Soviet drawn images](https://trip-for-the-soul.ru/foto/chto-gotovili-v-sssr-na-kazhdyj-den.html)
