import React, { useState, useEffect } from "react";
import {
  Icon,
  Menu,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";

function OtherProjects({ setSelected, role }) {
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
        Other Projects:
      </Menu.Item>
      <Menu.Item as="a" href="https://usda2022.asi-gis.com/">
          USDA 2022
        </Menu.Item>
        <Menu.Item as="a" href="https://alpha.asi-gis.com/">Alpha GIS</Menu.Item>
    </Menu>
  );
}

export default OtherProjects;
