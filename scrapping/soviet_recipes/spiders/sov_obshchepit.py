from collections import defaultdict

import json
import os
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
                    category_or_subcategory.xpath(".//text()").get()

            # If it's a subcategory, yield a dict with category and subcategory
            elif category_or_subcategory.xpath("self::h4"):
                subcategory = category_or_subcategory.xpath(".//text()").get()

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
            recipe_name = recipe.xpath(".//text()").get()
            recipe_url = recipe.xpath(".//@href").get()

            req = scrapy.Request(recipe_url, callback=self.parse_recipe)
            req.meta["category"] = response.meta["category"]
            req.meta["subcategory"] = response.meta["subcategory"]
            req.meta["recipe_name"] = recipe_name

            yield req

    def parse_recipe(self, response):
        main_block = response.xpath("//dd[@class='postcontent']")
        ingredients = []

        # All ingredients are in h3's ...among a lot of other things
        # We will include only the h3's that are after "Cостав" and before "Приготовление"
        h3s = main_block.xpath("//h3")

        in_ingredient_section = False

        for h3 in h3s:
            h3_strong = h3.xpath(".//strong//text()").get()

            if h3_strong:
                if "состав".casefold() in h3_strong.casefold():
                    in_ingredient_section = True
                    continue

                if "приготовление".casefold() in h3_strong.casefold():
                    break

            if in_ingredient_section:
                ingredient = clean_string(h3.xpath(".//text()").get())

                if ingredient:
                    ingredients.append(ingredient)

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
