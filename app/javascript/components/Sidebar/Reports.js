import React from "react";
import { Icon, Menu } from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";

function Reports({ setSelected, role }) {
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
        Reports:
      </Menu.Item>
      {role === "Admin" ||
        (role === "Manager" && (
          <>
            <Menu.Item as="a" href="/daily_progress_reports">
              Daily Progress
            </Menu.Item>
          </>
        ))}
      <Menu.Item as="a" href="/easements_to_fly">
        Easements to Fly
      </Menu.Item>
      <Menu.Item as="a" href="/easements_with_multiple_coverages">
        Easements with Multiple Coverages
      </Menu.Item>
      <Menu.Item as="a" href="/photo_index_tracker">
        Photo Index Tracker
      </Menu.Item>
      <Menu.Item as="a" href="/eo_tracker">
        EO Tracker
      </Menu.Item>
      <Menu.Item as="a" href="/flight_crew_report">
        Flight Crew Report
      </Menu.Item>
      <Menu.Item as="a" href="/contractor_breakdown_by_state">
        Contractor Breakdown by State
      </Menu.Item>
      <Menu.Item as="a" href="/flying_status_reports/index">
        Flying Status
      </Menu.Item>
      {/* <Menu.Item as="a" href="/tiles_wip">
        Tiles WIP
      </Menu.Item> */}
      <Menu.Item as="a" href="/wip_by_state">
        WIP by State
      </Menu.Item>
      <Menu.Item as="a" href="/tile_status">
        Tile Status
      </Menu.Item>
      <Menu.Item as="a" href="/content_file_status">
        Content File Status
      </Menu.Item>
      <Menu.Item as="a" href="/tile_dump_compare/index">
        Tile Dump Compare
      </Menu.Item>
      <Menu.Item as="a" href="/ready_to_ship">
        Ready to Ship
      </Menu.Item>
      <Menu.Item as="a" href="/packing_slip_worksheet">
        Packing Slip Worksheets
      </Menu.Item>
      <Menu.Item as="a" href="/invoice">
        Invoice
      </Menu.Item>
      <Menu.Item as="a" href="/total_delivery">
        Total Delivery
      </Menu.Item>
      <Menu.Item as="a" href="/total_delivery_by_state_and_contractor">
        Total Delivery State & Contractor
      </Menu.Item>
      <Menu.Item as="a" href="/total_delivery_by_state_and_county">
        Total Delivery State & Counties
      </Menu.Item>
    </Menu>
  );
}

export default Reports;
