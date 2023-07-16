from collections import defaultdict

import json
import re
import scrapy


class SovObshchepitSpider(scrapy.Spider):

    name = "sov-obshchepit"
    allowed_domains = ["sov-obshchepit.ru"]
    start_urls = ["https://sov-obshchepit.ru/retsepty"]

    nested_index = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    # category: { subcategory: { recipe: [] } }

    def __init__(self, nested_output=None, *args, **kwargs):
        super(SovObshchepitSpider, self).__init__(*args, **kwargs)

        # TODO: check if nested_output is a valid path
        if nested_output:
            self.nested_output = nested_output

    def closed(self, reason):
        if reason != "finished":
            return

        if not self.nested_output:
            return

        # Save the nested raw data to a file
        with open(self.nested_output, "w", encoding="utf-8") as f:
            json.dump(self.nested_index, f, ensure_ascii=False)

    def parse(self, response):
        main_block = response.xpath("//div[@class='postcontent']")

        # All categories are h2's, subcategories are h4's
        categories_and_subcategories = main_block.xpath("//h2 | //h4")

        # Iterate over categories and subcategories
        current_category = ""
        for category_or_subcategory in categories_and_subcategories:
            # If it's a category, update current_category
            if category_or_subcategory.xpath("self::h2"):
                current_category = \
                    "".join(category_or_subcategory.xpath(
                        ".//text()").getall())

            # If it's a subcategory, yield a dict with category and subcategory
            elif category_or_subcategory.xpath("self::h4"):
                subcategory = "".join(
                    category_or_subcategory.xpath(".//text()").getall())

                if subcategory:
                    subcategory_url = \
                        category_or_subcategory.xpath(".//@href").get()

                    req = scrapy.Request(
                        subcategory_url,
                        callback=self.parse_recipe_list
                    )
                    req.meta["category"] = current_category
                    req.meta["subcategory"] = subcategory

                    # Parse recipe list for this subcategory
                    yield req

    def parse_recipe_list(self, response):
        main_block = response.xpath("//div[@class='content']")

        # All recipes are in h1's
        recipes = main_block.xpath("//h1")

        for recipe in recipes:
            recipe_name = "".join(recipe.xpath(".//text()").getall())
            recipe_url = recipe.xpath(".//@href").get()

            req = scrapy.Request(recipe_url, callback=self.parse_recipe)
            req.meta["category"] = response.meta["category"]
            req.meta["subcategory"] = response.meta["subcategory"]
            req.meta["recipe_name"] = recipe_name

            yield req

    def parse_recipe(self, response):
        main_block = response.xpath("//dd[@class='postcontent']")

        # All ingredients are in h3's ...among a lot of other things
        # We will include only the h3's that are after "Cостав" and before "Приготовление"
        # Also, to be sure, we will h2 as well. "Cостав" usually goes afrer h2 with "Рецепт"
        headers = main_block.xpath("//h2 | //h3")
        header_texts = ["".join(header.xpath(".//text()").getall())
                        for header in headers]

        # Find all indices of "Рецепт", "Состав" and "Приготовление"
        # Using regex and whole word only search
        # recipe_indices = [i for i, text in enumerate(header_texts) if re.search(r"\bрецепт\b", text.casefold())]
        ingredient_indices = [i for i, text in enumerate(
            header_texts) if re.search(r"\bсостав\b", text.casefold())]
        cooking_indices = [i for i, text in enumerate(
            header_texts) if re.search(r"\bприготовление\b", text.casefold())]

        # Find a slice of headers that contains ingredients
        # It should be between "Cостав" and "Приготовление"
        # So index of "Приготовление" should be greater than index of "Cостав"
        ingredients = []

        if ingredient_indices and cooking_indices:
            ingredient_index = ingredient_indices[0]
            cooking_index = 0

            # TODO: better way to find overlapping indices
            for index in cooking_indices:
                if index > ingredient_index:
                    cooking_index = index
                    break

            ingredients = header_texts[ingredient_index + 1:cooking_index]

        if ingredients:
            ingredients = [
                clean_string(ingredient) for ingredient in ingredients
            ]

        # Unpack values
        category = clean_string(response.meta["category"])
        subcategory = clean_string(response.meta["subcategory"])
        recipe_name = clean_string(response.meta["recipe_name"])

        self.nested_index[category][subcategory][recipe_name] = ingredients

        yield {
            "category": category,
            "subcategory": subcategory,
            "recipe_name": recipe_name,
            "ingredients": ingredients
        }


def clean_string(string):
    return "".join([char for char in string if char.isprintable()]).strip()
