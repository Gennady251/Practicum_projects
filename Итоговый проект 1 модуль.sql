/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Геннадий (Гена) Гордиевский
 * Дата: 29.10.2024
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

-- Напишите ваш запрос здесь
-- Определим аномальные значения (выбросы) по значению перцентилей:
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
-- Выведем объявления без выбросов:
good_data AS (SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id)),
cat_reg AS (SELECT gd.id,        				 -- Разберем данные по регионам и активности объявлений, а также выведем необходимые для дальнейших рассчетов
					CASE 
					 WHEN city = 'Санкт-Петербург'
					 THEN 'Санкт-Петербург'
					 ELSE 'ЛенОбл'
					END AS region,    			 -- Регион объявлений
					CASE 
            		 WHEN days_exposition BETWEEN 1 AND 30 
            		 THEN 'до месяца'
            		 WHEN days_exposition BETWEEN 31 AND 90
            		 THEN 'до трех месяцев'
            		 WHEN days_exposition BETWEEN 91 AND 180
            		 THEN 'до полугода'
            		 ELSE 'более полугода'
					END AS category_d,    		 -- Активность объявлений
					last_price,					 -- Цена недвижимости
					f.total_area,				 -- Площадь недвижимости
					f.living_area,				 -- Жилая площадь
					f.kitchen_area,				 -- Площадь кухни
					f.balcony,					 -- Количество балконов в квартире
					f.rooms,					 -- Количество комнат
					f.airports_nearest			 -- Растояние до аэропорта
			 FROM good_data AS gd
			 JOIN real_estate.flats AS f ON gd.id=f.id
			 JOIN real_estate.city AS c ON f.city_id=c.city_id
			 JOIN real_estate.type AS t ON f.type_id=t.type_id
			 JOIN real_estate.advertisement AS a ON gd.id=a.id)
-- Выведем основной запрос
SELECT region,															-- Регион
	   category_d,														-- Активность
	   ROUND(AVG(total_area)::NUMERIC, 2) AS avg_total_area, 			-- Средняя площадь квартиры
	   ROUND(AVG(last_price)::NUMERIC, 2) AS avg_last_price, 			-- Средняя стоимость квартиры
	   ROUND(AVG(last_price/total_area)::numeric, 2) AS avg_price_m2,	-- Средняя цена за м2
	   COUNT(id) AS count_not,											-- Количество объявлений
	   ROUND(AVG(living_area)::numeric, 2) AS avg_liv_area,				-- Средняя жилая площадь
       ROUND(AVG(kitchen_area)::numeric, 2) AS avg_kitchen,				-- Средняя площадь кухни
       ROUND(AVG(airports_nearest)::numeric, 2) AS avg_airport,			-- Среднее растояние до аэропорта
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS med_b,	-- Медиана количетсва балконов в квартире
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS med_r		-- Медиана количества комнат
FROM cat_reg
GROUP BY region,
		 category_d
ORDER BY avg_price_m2 DESC

-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

-- Напишите ваш запрос здесь
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
	-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT *
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
	-- Выведем объявления без выбросов:
good_data AS (SELECT *
FROM real_estate.advertisement
WHERE id IN (SELECT id FROM filtered_id)),
expo_remov AS (SELECT gd.id,
				  EXTRACT(MONTH FROM a.first_day_exposition) AS mont_expo,
	 			  EXTRACT(MONTH FROM a.first_day_exposition+a.days_exposition*INTERVAL'1 day') AS mont,							-- Месяц публикации
		 		  a.days_exposition,																				-- Количество дней нахождения объявления на сайте
	   			  a.last_price,																						-- Стоимость квартиры
	   			  f.total_area																						-- Площаль квартиры
			   FROM good_data AS gd
			   JOIN real_estate.flats AS f ON gd.id=f.id 
  			   JOIN real_estate.advertisement AS a ON gd.id=a.id),
expo AS (SELECT mont_expo,
				COUNT(mont_expo) AS count_expo,
				ROUND(AVG(last_price)::NUMERIC, 2) AS avg_last_price,					-- Средняя цена квартиры
 				ROUND(AVG(total_area)::NUMERIC, 2) AS avg_total_area_e,					-- Средняя площаль квартиры
 				ROUND(AVG(last_price/total_area)::NUMERIC, 2) AS avg_price_m2_e			-- Средняя цена за квадратный метр
				FROM expo_remov AS er
				GROUP BY mont_expo),
remov AS (SELECT mont,
				 COUNT(days_exposition) AS count_remov
		  FROM expo_remov
		  WHERE days_exposition IS NOT NULL
		  GROUP BY mont),
info AS (SELECT er.mont,															-- Месяц
 		count(days_exposition) AS count_expo,												-- Количество публикаций 
 		COUNT(r.mont) AS count_remov, 											-- Количетсво снятых публикаций
 		ROUND((AVG(days_exposition)::numeric), 0) AS avg_days_exposition,		-- Среднее количество дней нахождения объявления на сайте
 		ROUND(AVG(last_price)::NUMERIC, 2) AS avg_last_price,					-- Средняя цена квартиры
 		ROUND(AVG(total_area)::NUMERIC, 2) AS avg_total_area_r,					-- Средняя площаль квартиры
 		ROUND(AVG(last_price/total_area)::NUMERIC, 2) AS avg_price_m2_r			-- Средняя цена за квадратный метр
 FROM expo_remov AS er
 JOIN remov AS r ON er.mont=r.mont
 GROUP BY er.mont
 ORDER BY er.mont)
 SELECT CASE e.mont_expo
 		 WHEN 1
 		 THEN 'январь'
 		 WHEN 2
 		 THEN 'февраль'
 		 WHEN 3
 		 THEN 'март'
 		 WHEN 4
 		 THEN 'апрель'
 		 WHEN 5
 		 THEN 'май'
 		 WHEN 6
 		 THEN 'июнь'
 		 WHEN 7
 		 THEN 'июль'
 		 WHEN 8
 		 THEN 'август'
 		 WHEN 9
 		 THEN 'сентябрь'
 		 WHEN 10
 		 THEN 'октябрь'
 		 WHEN 11
 		 THEN 'ноябрь'
 		 WHEN 12
 		 THEN 'декабрь'
 		END AS mont,
 		e.count_expo,
 		count_remov,
 		avg_days_exposition,				-- Среднее количество дней
 		i.avg_last_price,					-- Стоимость квартиры
 		avg_total_area_e,					-- Средняя площаль квартиры опубликованных объявлений
 		avg_total_area_r,					-- Средняя площаль квартиры снятых объявлений
 		avg_price_m2_e,						-- Средняя цена за квадратный метр опубликованных объявлений
 		avg_price_m2_r						-- Средняя цена за квадратный метр снятых объявлений
 		FROM info AS i
 		JOIN expo AS e ON i.mont=e.mont_expo
 
 
 
-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

-- Напишите ваш запрос здесь
 WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
-- Выведем объявления без выбросов:
good_data AS (SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id)),
cat_reg AS (SELECT gd.id,        					 -- Разберем данные по регионам и активности объявлений, а также выведем необходимые для дальнейших рассчетов
					CASE 
					 WHEN city = 'Санкт-Петербург'
					 THEN NULL
					 ELSE city
					END AS region,    			 	 -- Регион объявлений
				   days_exposition,
				   last_price,						 -- Цена недвижимости
				   f.total_area						 -- Площадь недвижимости
			 FROM good_data AS gd
			 JOIN real_estate.flats AS f ON gd.id=f.id
			 JOIN real_estate.city AS c ON f.city_id=c.city_id
			 JOIN real_estate.type AS t ON f.type_id=t.type_id
			 JOIN real_estate.advertisement AS a ON gd.id=a.id),
-- Выведем информацию
info AS (SELECT region,															-- Регион
	  			ROUND(AVG(total_area)::NUMERIC, 2) AS avg_total_area, 			-- Средняя площадь квартиры
	   			ROUND(AVG(last_price)::NUMERIC, 2) AS avg_last_price, 			-- Средняя стоимость квартиры
	  			ROUND(AVG(last_price/total_area)::numeric, 2) AS avg_price_m2,	-- Средняя цена за м2
	   			COUNT(id) AS count_expo,										-- Количество объявлений в населенном пункте
			    COUNT(days_exposition) AS count_remov,							-- Количество снятых 
			    (SELECT count(*) FROM filtered_id) AS count_ads,			    -- Количество всех объявлений
			    ROUND(AVG(days_exposition)::NUMERIC, 0) AS avg_days_expo,		-- Количество дней нахождения объявления на сайте
	   			ROW_NUMBER() OVER(ORDER BY COUNT(id) DESC) AS rank_count_expo,	-- Ранжирование по количеству объявлений
	   			NTILE(4) OVER(ORDER BY ((AVG(cr.days_exposition))) desc) AS rnk_days  					-- Активность-ранк
		FROM cat_reg AS cr
		WHERE region IS NOT NULL
		GROUP BY region)
-- Основной запрос
SELECT region,																	-- Регион
	   avg_total_area,															-- Средняя площадь квартиры
	   avg_last_price,															-- Средняя стоимость квартиры
	   avg_price_m2,															-- Средняя цена за м2
	   count_expo,																-- Количество объявлений в населенном пункте
	   ROUND((count_remov/count_expo::NUMERIC), 2) AS per_ads,					-- Доля снятых объявлений от общего количества объявлений
	   avg_days_expo,															-- Количество дней нахождения объявления на сайте
	   rank_count_expo,															-- Ранжирование по количеству объявлений
	   rnk_days
FROM info
ORDER BY rank_count_expo
LIMIT 15
 