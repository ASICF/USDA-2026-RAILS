import React, { useState, useEffect } from "react";
import {
  Dropdown,
  DropdownDivider,
  Menu,
  Icon,
  Sidebar,
  Header,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import "./Styles/default";
import JobTracker from "./JobTracker";
import SiteSidebar from "./SiteSidebar";
import axios from "axios";

const SiteHeader = (props) => {
  const [width, setWidth] = useState(window.innerWidth);

  const [loggedOut, setLoggedOut] = useState(false);

  // If user is not signed in
  if (!props.current_user) {
    return (
      <Menu inverted fixed="top" className="top_menu">
        <Dropdown
          item
          icon={null}
          text={
            <Header inverted as="h5" style={{ margin: 0 }}>
              <Icon name="globe" />
              <Header.Content>USDA 2024</Header.Content>
            </Header>
          }
        >
          <Dropdown.Menu style={{ width: 225 }}>
            <Dropdown.Item as="a" href="/" data-turbolinks="false">
              Home
            </Dropdown.Item>
            <Dropdown.Header>Historic Projects</Dropdown.Header>
            <Dropdown.Item as="a" href="https://usda2022.asi-gis.com/">
              USDA {props.project_year}
            </Dropdown.Item>
            <Dropdown.Header>Other Links</Dropdown.Header>
            <Dropdown.Item as="a" href="https://alpha.asi-gis.com/">
              Alpha
            </Dropdown.Item>
          </Dropdown.Menu>
        </Dropdown>
        {props.development === true && (
          <Menu.Item style={{ background: "#2a2a2a" }}>Dev</Menu.Item>
        )}
      </Menu>
    );
  }

  // Get the User Info
  const role = props.current_user.role;
  const approved = props.current_user.approved;
  const fullName =
    props.current_user.first_name + " " + props.current_user.last_name;

  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth);
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  const logout = () => {
    axios
      .get("/users/sign_out", {
        authenticity_token: props.token,
      })
      .then((res) => {
        setLoggedOut(true);
        console.error(res);
        window.location = "/";
      });
  };

  return (
    <div>
      {width > 768 && (
        <Menu inverted fixed="top" className="top_menu">
          <Dropdown
            item
            icon={null}
            trigger={
              <Header inverted as="h5" style={{ margin: 0 }}>
                <Icon name="globe" />
                <Header.Content>USDA 2024</Header.Content>
              </Header>
            }
          >
            <Dropdown.Menu style={{ width: 225 }}>
              <Dropdown.Item as="a" href="/" data-turbolinks="false">
                Home
              </Dropdown.Item>
              <Dropdown.Header>Historic Projects</Dropdown.Header>
              <Dropdown.Item as="a" href="https://usda2022.asi-gis.com/">
                USDA {props.project_year}
              </Dropdown.Item>
              <Dropdown.Header>Other Links</Dropdown.Header>
              <Dropdown.Item as="a" href="https://alpha.asi-gis.com/">
                Alpha
              </Dropdown.Item>
            </Dropdown.Menu>
          </Dropdown>
          {props.development === true && (
            <Menu.Item style={{ background: "#2a2a2a" }}>Dev</Menu.Item>
          )}
          <Dropdown item text="Manage">
            <Dropdown.Menu style={{ width: 225 }}>
              {role === "Admin" || role === "Manager" ? (
                <Dropdown item text="Equipment">
                  <Dropdown.Menu>
                    <Dropdown.Item
                      as="a"
                      href="/companies"
                      data-turbolinks="false"
                    >
                      Companies
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href="/planes"
                      data-turbolinks="false"
                    >
                      Planes
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href="/cameras"
                      data-turbolinks="false"
                    >
                      Cameras
                    </Dropdown.Item>
                  </Dropdown.Menu>
                </Dropdown>
              ) : null}

              {role === "Admin" && (
                <Dropdown item text="Admin">
                  <Dropdown.Menu>
                    <Dropdown.Item as="a" href="/users" data-turbolinks="false">
                      Users
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href="/report_history"
                      data-turbolinks="false"
                    >
                      Report History
                    </Dropdown.Item>
                  </Dropdown.Menu>
                </Dropdown>
              )}

              <Dropdown.Item as="a" href="/invoices" data-turbolinks="false">
                Invoices
              </Dropdown.Item>
              <Dropdown.Item as="a" href="/mail_groups" data-turbolinks="false">
                Mail Groups
              </Dropdown.Item>

              {role === "Admin" || role === "Manager" || role === "Reviewer" ? (
                <Dropdown item text="Excel Exports">
                  <Dropdown.Menu>
                    <Dropdown.Item
                      as="a"
                      href={`/excel_export?type=tiles`}
                      data-turbolinks="false"
                    >
                      Excel Export (Tiles)
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href={`/excel_export?type=all`}
                      data-turbolinks="false"
                    >
                      Excel Export (Full)
                    </Dropdown.Item>
                  </Dropdown.Menu>
                </Dropdown>
              ) : null}
            </Dropdown.Menu>
          </Dropdown>
          {role === "Admin" || role === "Manager" ? (
            <Dropdown item text="Inputs">
              <Dropdown.Menu style={{ width: 225 }}>
                {role === "Admin" ? (
                  <Dropdown item text="Admin">
                    <Dropdown.Menu>
                      <Dropdown.Item
                        as="a"
                        href={`/easements/new`}
                        data-turbolinks="false"
                      >
                        Buffered Easements
                      </Dropdown.Item>
                    </Dropdown.Menu>
                  </Dropdown>
                ) : null}
                <Dropdown item text="Data">
                  <Dropdown.Menu>
                    <Dropdown.Item
                      as="a"
                      href={`/footprints/new`}
                      data-turbolinks="false"
                    >
                      Footprints
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href={`/photo_index/new`}
                      data-turbolinks="false"
                    >
                      Photo Index
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href={`/frame_centers/new`}
                      data-turbolinks="false"
                    >
                      Frame Centers
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href={`/tile_dump`}
                      data-turbolinks="false"
                    >
                      Tile Dump
                    </Dropdown.Item>
                  </Dropdown.Menu>
                </Dropdown>

                <Dropdown item text="Rejections & Approvals">
                  <Dropdown.Menu>
                    <Dropdown.Item
                      as="a"
                      href={`/rejections/new`}
                      data-turbolinks="false"
                    >
                      Tile Rejections
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href={`/unreject_tile`}
                      data-turbolinks="false"
                    >
                      Unreject Tile
                    </Dropdown.Item>
                    {/* <Dropdown.Item
                      as="a"
                      href={`/usda_approve`}
                      data-turbolinks="false"
                    >
                      USDA Approved
                    </Dropdown.Item> */}
                  </Dropdown.Menu>
                </Dropdown>
              </Dropdown.Menu>
            </Dropdown>
          ) : null}
          <Dropdown item text="Reports">
            <Dropdown.Menu style={{ width: 225 }}>
              <Dropdown item text="Flight">
                <Dropdown.Menu>
                  {role === "Admin" || role === "Manager" ? (
                    <>
                      <Dropdown.Item
                        as="a"
                        href={`/daily_progress_reports`}
                        data-turbolinks="false"
                      >
                        Daily Progress
                      </Dropdown.Item>
                      <Dropdown.Item
                        as="a"
                        href={`/weekly_progress_reports`}
                        data-turbolinks="false"
                      >
                        Weekly Progress
                      </Dropdown.Item>
                    </>
                  ) : null}
                  <Dropdown.Item
                    as="a"
                    href={`/easements_to_fly`}
                    data-turbolinks="false"
                  >
                    Easements to Fly
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/easements_with_multiple_coverages`}
                    data-turbolinks="false"
                  >
                    Easements with Multiple Coverages
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/photo_index_tracker`}
                    data-turbolinks="false"
                  >
                    Photo Index Tracker
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/eo_tracker`}
                    data-turbolinks="false"
                  >
                    EO Tracker
                  </Dropdown.Item>
                  {/* <Dropdown.Item
                    as="a"
                    href={`/flight_crew_report`}
                    data-turbolinks="false"
                  >
                    Flight Crew Report
                  </Dropdown.Item> */}
                  <Dropdown.Item
                    as="a"
                    href={`/contractor_breakdown_by_state`}
                    data-turbolinks="false"
                  >
                    Contractor Breakdown by State
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/flying_status_reports/index`}
                    data-turbolinks="false"
                  >
                    Flying Status
                  </Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>

              <Dropdown item text="Production">
                <Dropdown.Menu>
                  {/* <Dropdown.Item
                    as="a"
                    href={`/tiles_wip`}
                    data-turbolinks="false"
                  >
                    Tiles WIP
                  </Dropdown.Item> */}
                  <Dropdown.Item
                    as="a"
                    href={`/wip_by_state`}
                    data-turbolinks="false"
                  >
                    WIP by State
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/tile_status`}
                    data-turbolinks="false"
                  >
                    Tile Status
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/content_file_status`}
                    data-turbolinks="false"
                  >
                    Content File Status
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/tile_dump_compare/index`}
                    data-turbolinks="false"
                  >
                    Tile Dump Compare
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/raw_tiff_compare`}
                    data-turbolinks="false"
                  >
                    Raw Tiff Compare
                  </Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>
              <Dropdown item text="Delivery">
                <Dropdown.Menu>
                  <Dropdown.Item
                    as="a"
                    href={`/ready_to_ship`}
                    data-turbolinks="false"
                    className="dropdown_header"
                  >
                    Ready to Ship
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/packing_slip_worksheet`}
                    data-turbolinks="false"
                  >
                    Packing Slip Worksheets
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/delivery_report`}
                    data-turbolinks="false"
                  >
                    Delivery Report
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/invoices`}
                    data-turbolinks="false"
                  >
                    Invoices
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/invoice_nestid`}
                    data-turbolinks="false"
                  >
                    Invoice NestID
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/total_delivery`}
                    data-turbolinks="false"
                  >
                    Total Delivery
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/total_delivery_by_state_and_contractor`}
                    data-turbolinks="false"
                  >
                    Total Delivery State & Contractor
                  </Dropdown.Item>
                  <Dropdown.Item
                    as="a"
                    href={`/total_delivery_by_state_and_county`}
                    data-turbolinks="false"
                  >
                    Total Delivery State & Counties
                  </Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>
            </Dropdown.Menu>
          </Dropdown>

          {role === "Admin" || role === "Manager" ? (
            <Dropdown item text="Exports">
              <Dropdown.Menu style={{ width: 225 }}>
                <Dropdown.Item
                  as="a"
                  href={`/county_status_and_cut_file`}
                  data-turbolinks="false"
                >
                  County Status & Cut File
                </Dropdown.Item>
                <Dropdown item text="Final Delivery">
                  <Dropdown.Menu>
                    <Dropdown.Item
                      as="a"
                      href={`/final_delivery/move_tiles_to_utm_folder`}
                      data-turbolinks="false"
                    >
                      Move Tiles to UTM Folder
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href={`/final_delivery/move_tiles_from_utm_folder`}
                      data-turbolinks="false"
                    >
                      Move Tiles from UTM Folder
                    </Dropdown.Item>
                    <Dropdown.Item
                      as="a"
                      href={`/final_delivery/generate_metadata_and_assign_psn`}
                      data-turbolinks="false"
                    >
                      Generate Metadata and Assign PSN
                    </Dropdown.Item>
                  </Dropdown.Menu>
                </Dropdown>
              </Dropdown.Menu>
            </Dropdown>
          ) : null}

          <Dropdown
            item
            as="a"
            href={`/timeline`}
            text="Timeline"
            icon={null}
          ></Dropdown>

          <Dropdown.Menu className="float right">
            {approved === true && <JobTracker />}

            {loggedOut === false ? (
              <Dropdown
                item
                icon={null}
                trigger={
                  <Header
                    inverted
                    as="h5"
                    style={{ margin: 0, fontWeight: "normal" }}
                  >
                    <Icon name="user" />
                    <Header.Content>{fullName}</Header.Content>
                  </Header>
                }
              >
                <Dropdown.Menu>
                  <Dropdown.Item onClick={() => logout()}>
                    Log out
                  </Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>
            ) : (
              <Dropdown item icon="user">
                <Dropdown.Menu>
                  <Dropdown.Item as="a" href="/users/sign_in" className="item">
                    Log In
                  </Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>
            )}
          </Dropdown.Menu>
        </Menu>
      )}

      {width <= 768 && (
        <Menu inverted fixed="top" className="top_menu">
          <Dropdown.Menu>
            <SiteSidebar role={role} />
          </Dropdown.Menu>

          <Dropdown.Menu className="float right">
            {approved === true && <JobTracker icon="alarm" />}

            {loggedOut === false ? (
              <Dropdown item icon="user">
                <Dropdown.Menu>
                  <Dropdown.Item className="fullname">{fullName}</Dropdown.Item>
                  <Dropdown.Item onClick={() => logout()}>
                    Log out
                  </Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>
            ) : (
              <Dropdown item icon="user">
                <Dropdown.Menu>
                  <Dropdown.Item as="a" href="/users/sign_in" className="item">
                    Login
                  </Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>
            )}
          </Dropdown.Menu>
        </Menu>
      )}
    </div>
  );
};
export default SiteHeader;
