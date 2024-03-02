import React from "react";
import {
  Icon,
  Menu,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";

function Inputs({ setSelected, role }) {
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
      Inputs
      </Menu.Item>
      {role === "Admin" ? (
          <>
            <Menu.Item as="a" href="/easements/new">
              Buffered Easements
            </Menu.Item>
          </>
        ) : null }
        <Menu.Item as="a" href="/footprints/new">
          Footprints
        </Menu.Item>
        <Menu.Item as="a" href="/photo_index/new">
          Photo Index
        </Menu.Item>
        <Menu.Item as="a" href="/frame_centers/new">
          Frame Centers
        </Menu.Item>
        <Menu.Item as="a" href="/tile_dump">
          Tile Dump
        </Menu.Item>
        <Menu.Item as="a" href="/rejections/new">
          Tile Rejections
        </Menu.Item>
        <Menu.Item as="a" href="/unreject_tile">
          Unreject Tile
        </Menu.Item>
    </Menu>
  );
}

export default Inputs;
