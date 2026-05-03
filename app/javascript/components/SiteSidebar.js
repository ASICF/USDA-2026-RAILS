import React, { useState, useEffect } from "react";
import {
  Icon,
  Segment,
  Dropdown,
  Menu,
  Sidebar,
  Modal,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import "./Styles/default";
import OtherProjects from "./Sidebar/OtherProjects";
import Manage from "./Sidebar/Manage";
import Inputs from "./Sidebar/Inputs";
import Reports from "./Sidebar/Reports";
import Exports from "./Sidebar/Exports";
function SiteSidebar({ role }) {

  //Sidebar Visibility Logic:
  const [showSidebar, setShowSidebar] = useState(false);

  //Sidebar Resizing Logic:
  // const [height, setHeight] = useState(window.innerHeight);
  const [width, setWidth] = useState(window.innerWidth);
  const [selected, setSelected] = useState(null);

  useEffect(() => {
    const handleResize = () => {
      // setHeight(window.innerHeight);
      setWidth(window.innerWidth);
    };
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  return (
    <div>
      <Menu attached inverted className="top_menu">
        <Menu.Item onClick={() => setShowSidebar(!showSidebar)}>
          {width > 768 ? null : <Icon name="sliders" />}
        </Menu.Item>
      </Menu>

      <Sidebar
        animation="overlay"
        visible={showSidebar}
        onHide={() => setShowSidebar(false)}
        className="side"
      >
        {selected === null && (
          <Menu vertical fluid attached inverted>
            <Menu.Item
              onClick={() => setShowSidebar(false)}
              className="side-header"
            >
              <Icon name="close" /> 
              USDA 2026
            </Menu.Item>

            <Menu.Item as="a" href="/" className="home-sidebar">
              <Icon name="home" />
              Home
            </Menu.Item>

            <Menu.Item
              onClick={() => {
                setSelected("Projects");
              }}
            >
              Other Projects
            </Menu.Item>
            {role === "Admin" || role === "Manager" || role === "Reviewer" ? (
              <>
                <Menu.Item
                  onClick={() => {
                    setSelected("Manage");
                  }}
                >
                  Manage
                </Menu.Item>
              </>
            ) : null}
            {role === "Admin" || role === "Manager" ? (
              <>
                <Menu.Item
                  onClick={() => {
                    setSelected("Inputs");
                  }}
                >
                  Inputs
                </Menu.Item>
              </>
            ) : null}
            <Menu.Item
              onClick={() => {
                setSelected("Reports");
              }}
            >
              Reports
            </Menu.Item>
            {role === "Admin" || role === "Manager" ? (
              <Menu.Item
                onClick={() => {
                  setSelected("Exports");
                }}
              >
                Exports
              </Menu.Item>
            ) : null}
            <Menu.Item as="a" href="/timeline">
              Timeline
            </Menu.Item>
          </Menu>
        )}

        {selected === "Projects" && <OtherProjects setSelected={setSelected} />}
        {selected === "Manage" && (
          <Manage setSelected={setSelected} role={role} />
        )}
        {selected === "Inputs" && (
          <Inputs setSelected={setSelected} role={role} />
        )}
        {selected === "Reports" && (
          <Reports setSelected={setSelected} role={role} />
        )}
        {selected === "Exports" && (
          <Exports setSelected={setSelected} role={role} />
        )}
      </Sidebar>
    </div>
  );
}

export default SiteSidebar;
