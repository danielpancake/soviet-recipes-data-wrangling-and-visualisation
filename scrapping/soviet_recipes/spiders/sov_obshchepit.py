import scrapy


class SovObshchepitSpider(scrapy.Spider):
    name = "sov-obshchepit"
    allowed_domains = ["sov-obshchepit.ru"]
    start_urls = ["https://sov-obshchepit.ru/retsepty"]

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
                ingredient = h3.xpath(".//text()").get()

                if ingredient:
                    ingredients.append(ingredient)

        yield {
            "category": response.meta["category"],
            "subcategory": response.meta["subcategory"],
            "recipe_name": response.meta["recipe_name"],
            "ingredients": ingredients
        }
