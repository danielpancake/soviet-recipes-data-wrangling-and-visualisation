# unnamed data wrangling yadda yadda project

## Project Description

1. Data Scraping
    1. Target websites
        - [Main source for Soviet recipes](https://sov-obshchepit.ru/)
        - Not used yet:
            - [Website "1000.menu"](https://1000.menu/catalog/recepty-sovetskix-vremen)
            - [Website "webspoon"](https://webspoon.ru/cuisine/kuhnja-sssr)
            - [Website "povarenok"](https://www.povarenok.ru/recipes/kitchen/101/?sort=date_create_asc&order=desc)
    2. Data format
        Data should follow this format:

        ```js
        {
            category: "string",
            subcategory: "string",
            recipe_name: "string",
            ingredients: [
                {
                    ingredient_name: "string",
                    amount: "number",
                    unit: "string",
                },
            ],
        }
        ```

2. Data Wrangling

    pass

3. Data Analysis

    pass

4. Data Visualization

    pass

## Misc

Visual inspiration: [Soviet drawn images](https://trip-for-the-soul.ru/foto/chto-gotovili-v-sssr-na-kazhdyj-den.html)
