create or replace PROCEDURE SMS_MAN_RECHARGE_EXP_LONGLIFE
AS
BEGIN

FOR i IN
(
  SELECT
    ser.phone_number,ser.subscription_id,bg.account_id
FROM
    plan_details_xvdn4              pdx,
    telstra_dedicated_account_def   tdad,
    telstra_dedicated_account       tda,
    service                         ser,
    billing_group_member            bgm,
    billing_group                   bg
WHERE
    pdx.planid = tdad.planid
    AND tdad.bucket_name = tda.telstra_account_id
    AND trunc(tda.expiry_date) = trunc(sysdate + 2)
    AND tdad.bucket_type = 'Monetary'
    AND tdad.bucket_name IN (
        '5016000',
        '5015000'
    )
    AND tda.phone_number = ser.phone_number
    AND ser.subscription_id = bgm.subscription_id
    AND bgm.billing_group_id = bg.id
    AND ser.status_id between 200 and 399
    AND NOT EXISTS (
        SELECT
            1
        FROM
            recharge_ticket rt
        WHERE
            rt.billing_group_id = bg.id
            AND rt.code = 'TIME'
    )
)
LOOP
  INSERT
  INTO
    sms_messages
    (
      id,
      status_id,
      mobilenumber,
      priority,
      MESSAGE,
      DATECREATE,
      SEND_DATE
    )
    VALUES
    (
      core_sys.nextoid,
      0,
      i.phone_number,
      1,
      'Your Woolworths Pre-paid Mobile recharge is due to expire in 2 days for mobile number '||i.phone_number||'. You can recharge via our mobile app or online at mobile.woolworths.com.au/recharge.',
      sysdate,
      sysdate
    );

  INSERT
  INTO
    history VALUES
    (
      core_sys.nextoid,
      i.account_id,
      'Subscription',
      i.subscription_id,
      NULL,
      SYSDATE,
      'Your Woolworths Pre-paid Mobile recharge is due to expire in 2 days for mobile number '||i.phone_number||'. You can recharge via our mobile app or online at mobile.woolworths.com.au/recharge.',
      'TELCO_BATCH',
      NULL,
      NULL
    );
  COMMIT;
END LOOP;
COMMIT;

END SMS_MAN_RECHARGE_EXP_LONGLIFE;