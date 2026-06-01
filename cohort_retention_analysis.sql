with clean_users as (
	select user_id, full_name, promo_signup_flag, 
	case 
		when cleaned_date ~ '^\d{1,2}-\d{1,2}-\d{4}$'
        then to_date(cleaned_date, 'DD-MM-YYYY')
        when cleaned_date ~ '^\d{1,2}-\d{1,2}-\d{2}$'
        then to_date(cleaned_date, 'DD-MM-YY')
        else null
	end	as cleaned_date_signup
	from (select *, 
	replace(
		replace(split_part(trim(signup_datetime), ' ', 1), '.', '-'),
			'/', '-') as cleaned_date from cohort_users_raw ) t),		
clean_events as (
	select event_id, user_id, event_type, revenue,
	case 
		when cleaned_date ~ '^\d{1,2}-\d{1,2}-\d{4}$'
        then to_date(cleaned_date, 'DD-MM-YYYY')
        when cleaned_date ~ '^\d{1,2}-\d{1,2}-\d{2}$'
        then to_date(cleaned_date, 'DD-MM-YY')
        else null
	end	as cleaned_date_event
	from (select *, 
	replace(
		replace(split_part(trim(event_datetime), ' ', 1), '.', '-'),
			'/', '-') as cleaned_date from cohort_events_raw ) t),
joined_together AS (
    select
        cu.user_id,
        cu.promo_signup_flag,
        cast(date_trunc('month', cu.cleaned_date_signup) as date) as cohort_month,
        cast(date_trunc('month', ce.cleaned_date_event) as date) as activity_month,
        cast((
            (date_part('year', ce.cleaned_date_event) - date_part('year', cu.cleaned_date_signup)) * 12
            +
            (date_part('month', ce.cleaned_date_event) - date_part('month', cu.cleaned_date_signup))
        ) as int) as month_offset
    from clean_users cu
    join clean_events ce
        on cu.user_id = ce.user_id
    where
        cu.cleaned_date_signup is not null
        and ce.cleaned_date_event is not null
        and ce.event_type is not null
        and ce.event_type <> 'test_event'
)
select promo_signup_flag, cohort_month, month_offset, count (distinct user_id) as users_total
from joined_together
where activity_month between '2025-01-01' and '2025-06-01'
group by promo_signup_flag, cohort_month, month_offset
order by promo_signup_flag, cohort_month, month_offset













