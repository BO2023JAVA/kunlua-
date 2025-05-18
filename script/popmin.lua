local M = {}

local twlayout={
  CardView;
  layout_width="wrap_content";
  layout_height="wrap_content";
  radius="10dp";
  {
    LinearLayout;
    paddingTop="10dp";
    paddingBottom="10dp";
    paddingLeft="14dp";
    paddingRight="14dp";
    gravity="center";
    orientation="horizontal";
    id = "tw_bg";
    backgroundColor="#FFEB9662";
    {
      TextView;
      id="tw_text";
      textColor="#ffffff";
      text="暂无提示内容！";
      gravity="center";
      layout_marginLeft="0dp";
      Typeface=Typeface.DEFAULT_BOLD;
    };
  };
};

function M.tw(con,color)
  local toast=Toast.makeText(activity,"提示",Toast.LENGTH_SHORT).setGravity(Gravity.BOTTOM, 0, 250).setView(loadlayout(twlayout))
  tw_bg.backgroundColor=color or 0xFFEB9662
  tw_text.text=tostring(con)
  toast.show()
end

return M


