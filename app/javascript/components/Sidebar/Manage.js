import React from "react";
import {
  Icon,
  Menu,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";

function Manage({ setSelected, role }) {
  console.log(role);

  return (
    <Menu vertical fluid inverted>
      <Menu.Item
        onClick={() => {
          setSelected(null);
        }}
        className="side-header"
      >
        <Icon name="left arrow" />
        Return to Menu
      </Menu.Item>
      <Menu.Item header style={{ textAlign: "center" }}>
      Manage
      </Menu.Item>
      {role === "Admin" || role === "Manager" ? (
          <>
            <Menu.Item as="a" href="/companies">
              Companies
            </Menu.Item>
            <Menu.Item as="a" href="/planes">
              Planes
            </Menu.Item>
            <Menu.Item as="a" href="/cameras">
              Cameras
            </Menu.Item>
          </>
        ) : null}
        {role === "Admin" ? (
          <>
            <Menu.Item as="a" href="/users">
              Users
            </Menu.Item>
            <Menu.Item as="a" href="/report_history">
              Report History
            </Menu.Item>
          </>
        ) : null}
        <Menu.Item as="a" href="/mail_groups">
          Mail Groups
        </Menu.Item>

        {role === "Admin" || role === "Manager" ? (
          <>
            <Menu.Item as="a" href={`/excel_export?type=tiles`}>
              Excel Export (Tiles)
            </Menu.Item>
            <Menu.Item as="a" href={`/excel_export?type=all`}>
              Excel Export (Full)
            </Menu.Item>
          </>
        ) : null}
    </Menu>
  );
}

export default Manage;
