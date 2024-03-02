import React, { Fragment } from "react";
import { Divider, Table } from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import MessageBox from "../../Shared/MessageBox";

export default function FlightCrewSL({ results }) {
  console.log("AllSitesByContractorAndStateSL", {
    results,
  });

  if (results.length === 0) {
    return (
      <MessageBox
        title={"No Records Found"}
        message={"Query returned no records"}
      />
    );
  }

  const renderRecords = () => {
    let list = [];

    var totals = {
      flown_by_name: results[0].flown_by_name,
      total_flown: 0,
      asi_accepted: 0,
      asi_rejected: 0,
      usda_accepted: 0,
      usda_rejected: 0,
    };

    var grand_total = {
      total_flown: 0,
      acres: 0,
      asi_accepted: 0,
      asi_rejected: 0,
      usda_accepted: 0,
      usda_rejected: 0,
    };

    for (let i = 0; i < results.length; i++) {
      let record = results[i];

      if (totals.flown_by_name != record.flown_by_name) {
        list.push(
          <Table.Row
            key={`summary_${i}`}
            style={{ background: "$light_gray", fontWeight: "bold" }}
          >
            <Table.Cell colSpan="4">Total</Table.Cell>
            <Table.Cell>{totals.total_flown}</Table.Cell>
            <Table.Cell>{totals.asi_accepted}</Table.Cell>
            <Table.Cell>{totals.asi_rejected}</Table.Cell>
            <Table.Cell>{totals.usda_accepted}</Table.Cell>
            <Table.Cell>{totals.usda_rejected}</Table.Cell>
          </Table.Row>
        );

        totals = {
          flown_by_name: record.flown_by_name,
          total_flown: 0,
          asi_accepted: 0,
          asi_rejected: 0,
          usda_accepted: 0,
          usda_rejected: 0,
        };
      }

      list.push(
        <Table.Row key={i}>
          <Table.Cell>{record.flown_by_name}</Table.Cell>
          <Table.Cell>{record.state_name}</Table.Cell>
          <Table.Cell>{record.pilot}</Table.Cell>
          <Table.Cell>{record.sensor_operator}</Table.Cell>
          <Table.Cell>{record.flown}</Table.Cell>
          <Table.Cell>{record.asi_accepted}</Table.Cell>
          <Table.Cell>{record.asi_rejected}</Table.Cell>
          <Table.Cell>{record.usda_accepted}</Table.Cell>
          <Table.Cell>{record.usda_rejected}</Table.Cell>
        </Table.Row>
      );

      // Update Totals
      totals.total_flown += record.flown;
      totals.asi_accepted += record.asi_accepted;
      totals.asi_rejected += record.asi_rejected;
      totals.usda_accepted += record.usda_accepted;
      totals.usda_rejected += record.usda_rejected;

      // Update grand totals
      grand_total.total_flown += record.flown;
      grand_total.asi_accepted += record.asi_accepted;
      grand_total.asi_rejected += record.asi_rejected;
      grand_total.usda_accepted += record.usda_accepted;
      grand_total.usda_rejected += record.usda_rejected;

      if (i == results.length - 1) {
        list.push(
          <Table.Row
            key={`summary_${i}_final`}
            style={{ background: "$light_gray", fontWeight: "bold" }}
          >
            <Table.Cell colSpan="4">Total</Table.Cell>
            <Table.Cell>{totals.total_flown}</Table.Cell>
            <Table.Cell>{totals.asi_accepted}</Table.Cell>
            <Table.Cell>{totals.asi_rejected}</Table.Cell>
            <Table.Cell>{totals.usda_accepted}</Table.Cell>
            <Table.Cell>{totals.usda_rejected}</Table.Cell>
          </Table.Row>
        );

        list.push(
          <Table.Row
            key={`grand_total`}
            style={{ background: "$light_gray", fontWeight: "bold" }}
          >
            <Table.Cell colSpan="4">Grand Total</Table.Cell>
            <Table.Cell>{grand_total.total_flown}</Table.Cell>
            <Table.Cell>{grand_total.asi_accepted}</Table.Cell>
            <Table.Cell>{grand_total.asi_rejected}</Table.Cell>
            <Table.Cell>{grand_total.usda_accepted}</Table.Cell>
            <Table.Cell>{grand_total.usda_rejected}</Table.Cell>
          </Table.Row>
        );
      }
    }

    return list;
  };

  return (
    <Fragment>
      <Divider />
      <Table celled textAlign="center">
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell>Company Name</Table.HeaderCell>
            <Table.HeaderCell>State Name</Table.HeaderCell>
            <Table.HeaderCell>Pilot</Table.HeaderCell>
            <Table.HeaderCell>SO</Table.HeaderCell>
            <Table.HeaderCell>Flown</Table.HeaderCell>
            <Table.HeaderCell>ASI Accepted</Table.HeaderCell>
            <Table.HeaderCell>ASI Rejected</Table.HeaderCell>
            <Table.HeaderCell>USDA Accepted</Table.HeaderCell>
            <Table.HeaderCell>USDA Rejected</Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>{renderRecords()}</Table.Body>
      </Table>
    </Fragment>
  );
}
