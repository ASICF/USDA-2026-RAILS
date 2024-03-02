import React, { useState, useEffect } from "react";
import {
  Icon,
  Menu,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";

function Exports({ setSelected, role }) {
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
      Exports: 
      </Menu.Item>
      <Menu.Item as="a" href="/county_status_and_cut_files">
        County Status and Cut File
      </Menu.Item>
      <Menu.Item as="a" href="/final_delivery/move_tiles_to_utm_folder">
        Move Tiles to UTM Folder
      </Menu.Item>
      <Menu.Item as="a" href="/final_delivery/move_tiles_from_utm_folder">
        Move Tiles from UTM Folder
      </Menu.Item>
      <Menu.Item as="a" href="/final_delivery/generate_metadata_and_assign_psn">
        Generate Metadata and Assign PSN
      </Menu.Item>
    </Menu>
  );
}

export default Exports;
