import scrapy


class SovObshchepitSpider(scrapy.Spider):
    name = "sov-obshchepit"
    allowed_domains = ["sov-obshchepit.ru"]
    start_urls = ["https://sov-obshchepit.ru/retsepty"]

    def parse(self, response):
        # Data should follow this format:
        #
        # {
        #   category: string,
        #   subcategory: string,
        #   recipe_name: string,
        #   ingredients: [
        #     {
        #       ingredient_name: string,
        #       amount: number,
        #       unit: string,
        #     },
        #   ],
        # }
        #

        main_block = response.xpath("//div[@class='postcontent']")

        # All categories are h2's, subcategories are h4's
        categories_and_subcategories = main_block.xpath("//h2 | //h4")

        # Iterate over categories and subcategories
        current_category = ""
        for category_or_subcategory in categories_and_subcategories:
            # If it's a category, update current_category
            if category_or_subcategory.xpath("self::h2"):
                current_category = category_or_subcategory.xpath(
                    ".//text()").get()

            # If it's a subcategory, yield a dict with category and subcategory
            elif category_or_subcategory.xpath("self::h4"):
                subcategory = category_or_subcategory.xpath(".//text()").get()

                if subcategory:
                    subcategory_url = \
                        category_or_subcategory.xpath(".//@href").get()
                    
                    req = scrapy.Request(subcategory_url, callback=self.parse_recipe_list)
                    req.meta["category"] = current_category
                    req.meta["subcategory"] = subcategory

                    # Parse recipe list for this subcategory
                    yield req

    def parse_recipe_list(self, response):

        main_block = response.xpath("//div[@class='content']")

        # All recipes are in h1's
        recipes = main_block.xpath("//h1")

        # Iterate over recipes
        for recipe in recipes:
            recipe_name = recipe.xpath(".//text()").get()

            if recipe_name:
                yield {
                    "category": response.meta["category"],
                    "subcategory": response.meta["subcategory"],
                    "recipe_name": recipe_name,
                }
